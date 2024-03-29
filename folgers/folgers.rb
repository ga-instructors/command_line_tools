require 'json'

MAIN_MENU_FILE = "#{File.dirname(__FILE__)}/main_menu.txt"
USAGE_FILE = "#{File.dirname(__FILE__)}/usage.txt"
WDI_CONFIG_DIR = File.expand_path("~/.wdi")
WDI_CONFIG_FILE = "#{WDI_CONFIG_DIR}/config.json"
WDI_CURRICULUM_FILE = "#{WDI_CONFIG_DIR}/curriculum.json"
WDI_STUDENTS_FILE = "#{WDI_CONFIG_DIR}/students.json"

class Folgers

  def initialize
    @COLLECTION_KEYS = [:contributors, :languages, :authors, :tags]
    @COMMAND_LINE_MODE = false
    @ORIGINAL_OPTIONS = ARGV

    @CURRICULUM = JSON.parse(try_load_file(WDI_CURRICULUM_FILE).read)
    @STUDENTS = JSON.parse(try_load_file(WDI_STUDENTS_FILE).read)

    option = ARGV.shift
    if option.nil?
      main_menu
    else
      @COMMAND_LINE_MODE = true
      if ["g", "generate", "-g"].include? option
        puts "Made: "
        puts make_new(ARGV.shift)
      elsif ["f","folders","-f"].include? option
        puts make_student_folders(ARGV.shift)
      elsif ["d", "distribute"].include? option
        puts distribute_to_students(ARGV.shift)
      elsif ["s","search"].include? option
        puts "Finding"
        search_for_exercise
      elsif ["t", "test"].include? option
        puts test_student_files(ARGV.shift)
      elsif ["-h", "help", "h"].include? option
        print File.read(USAGE_FILE)
      end
    end
  end

  def try_load_file filename
    if File.exists? filename
      return File.open(filename, "rb")
    else
      prompt_user_with("No #{filename} found! Certain features may not work.")
      return []
    end
  end

  def main_menu
    print File.read(MAIN_MENU_FILE)

    choice = $stdin.gets.chomp.to_i
    case choice
      when 1
        make_new_exercise
        system("clear")
        prompt_user_with("Created Successfully!")
        main_menu
      when 2
        search_for_exercise
        system("clear")
        main_menu
      when 3
        generate_index_file
        # system("clear")
        main_menu
      when 4
        make_student_folders
        main_menu
      when 5
        system("clear")
      else
        system("clear")
        prompt_user_with("PLEASE ENTER A VALID OPTION")
        main_menu
    end
  end

  def show_usage
    print File.read(MAIN_MENU_FILE)
  end

  def test_student_files(options=nil)
    valid_options = ["v", "-v", "verbose"]
    fails = []
    # expects students to have their tests in /Student_Name/assignment_name/spec
    Dir.glob("./*/*/spec/*_spec.rb").each do |file|
      unless valid_options.include? options
        `rspec #{file}`
        successful = $?
        unless successful == 0
          fails << file
        end
      else
        unless system("rspec #{file}")
          fails << file
        end
      end
    end
    puts "="*20
    fails.each do |failed|
      puts "#{failed} failed!"
    end
    puts "="*20
  end

  def distribute_to_students(source)
    if source == "" || source == nil
      assignment_dir = "ASSIGNMENT_FILES"
    else
      # clean source
      assignment_dir = source.gsub(/[^A-Za-z0-9\s]/,"")
    end
    source_dir = "#{Dir.pwd}/#{assignment_dir}"

    # directories to ignore when distributing a file
    ignored_files = [ assignment_dir, "INSTRUCTORS", "Readme.md" ]

    Dir.glob("*").each do |file|
      if !(ignored_files.include? file.to_s) && Dir.exists?(file)
        # only copies files that are not already present in student dir
        # this avoids overwriting their work
        files_present = Dir.entries(file) & Dir.entries(assignment_dir)
        files_to_copy = Dir.entries(assignment_dir) - files_present
        files_to_copy.each do |assignment_file|
          system("cp -R #{assignment_dir}/#{assignment_file} #{file}")
          puts "Distributed #{assignment_dir}/#{assignment_file} to #{file}"
        end
      end
    end
    nil
  end

  def make_student_folders(target_folder_input=nil)
    unless @COMMAND_LINE_MODE
      puts "What is the name of the student folder? (i.e. d01)"
      target_folder_input = gets.chomp
    end

    return prompt_user_with("Must specify folder name!") unless target_folder_input

    target_folder_name = target_folder_input.gsub(/[\s|\/]/,"")
    new_dir_path = "#{Dir.pwd}/#{target_folder_name}"

    begin
      Dir.mkdir(new_dir_path)
    rescue Exception => e
      unless e.class == Errno::EEXIST
        return
      end
    end

    puts "Making Student Folders"
    @STUDENTS.each do |student|
      # remove terminal white space and then replace internal spaces with underscores
      name = student['Name'] ? student['Name'].gsub(/ $|\n/,"").gsub(/^ /,"").gsub(/ +/,"_") : ""
      email = student['Email']
      github = student['GitHub'] ? student['GitHub'].gsub(/ $/,"") : ""
      student_folder_path = "#{new_dir_path}/#{name}"
      Dir.mkdir(student_folder_path)
      readme_file = File.open("#{student_folder_path}/README.md","w")
      readme_file.puts "Name: #{name}"
      readme_file.puts "Email: #{email}"
      readme_file.puts "GitHub: #{github}"
      readme_file.close
    end

    puts "Making INSTRUCTORS Folder"

    Dir.mkdir("#{new_dir_path}/INSTRUCTORS")
    instructor_gitkeep = File.open("#{new_dir_path}/INSTRUCTORS/.gitkeep", "w")
    instructor_gitkeep.close

    puts "Making ASSIGNMENT_FILES Folder"

    Dir.mkdir("#{new_dir_path}/ASSIGNMENT_FILES")
    assignment_files_gitkeep = File.open("#{new_dir_path}/ASSIGNMENT_FILES/.gitkeep", "w")
    assignment_files_gitkeep.close

    daily_readme = File.open("#{new_dir_path}/Readme.md","w")
    daily_readme.puts "#Readme.md"
    daily_readme.close

    "Finished making #{new_dir_path}"
  end

  def make_new_exercise
    @target_path = get_target_path

    id = Time.now.to_i

    puts "enter the unit number (i.e. 3.14): "
    unit = $stdin.gets.chomp
    puts "enter the lesson name (i.e. HTML and AJAX): "
    lesson_name = $stdin.gets.chomp
    puts "enter the title: "
    title = $stdin.gets.chomp
    puts "enter the language: "
    language = $stdin.gets.chomp
    puts "enter the author(s) (i.e. firstname lastname separated by commas): "
    authors = $stdin.gets.chomp.split(/\,\s+/)
    puts "enter tags (separated by spaces): "
    tags = $stdin.gets.chomp.split(/\s+/)

    puts "enter the length of the exercise (i.e. 'short', 'long', 'drill'): "
    length = $stdin.gets.chomp

    exercise_directory = "#{@target_path}/ex_#{id}"

    # assign learning object
    learning_objective = assign_learning_objective(unit)

    # make EX directory
    Dir.mkdir(exercise_directory)

    # make a solutions dir
    Dir.mkdir("#{exercise_directory}/solutions")

    gitkeep1 = File.open("#{exercise_directory}/solutions/.gitkeep", "w")
    gitkeep1.close

    # make a starters dir
    Dir.mkdir("#{exercise_directory}/starters")
    gitkeep2 = File.open("#{exercise_directory}/starters/.gitkeep", "w")
    gitkeep2.close

    readme_string = <<-EOS.gsub(/^\s*/, "")
      \##{title}

      \#\#\#Learning Objective:
      #{learning_objective}

      \#\#\#Overview:

      \#\#\#Spec:
    EOS

    readme = File.open([
      exercise_directory,
      "/README.md"
    ].join(""),"w" )

    readme.puts readme_string
    readme.close

    new_meta_file_path = [
      exercise_directory,
      "/meta.json"
    ].join("")

    f = File.open(new_meta_file_path, "w")

    meta_hash = {
      id: id,
      title: title,
      language: language,
      authors: authors,
      tags: tags,
      unit: unit,
      length: length,
      lesson_name: lesson_name,
      learning_objective: learning_objective
    }

    f.puts JSON.pretty_generate(meta_hash)

    f.close

    generate_index_file
  end

  def make_new(resource)
    return false if resource != "meta"
    # TODO: support more types of resources

    @target_path = Dir.pwd

    id = Time.now.to_i

    new_meta_file_path = [
      @target_path,
      "/meta.json"
    ].join("")

    f = File.open(new_meta_file_path, "w")

    # TODO: turn the building of this hash into its own function
    meta_hash = parse_argv(ARGV)
    meta_hash["id"] = id

    f.puts JSON.pretty_generate(meta_hash)

    f.close
    return meta_hash
  end

  def search_for_exercise
    unless @COMMAND_LINE_MODE
      attribute = get_attribute_of_exercise

      puts "enter your search query:"
      query = $stdin.gets.chomp
    else
      hash = parse_argv(@ORIGINAL_OPTIONS)
      if hash.keys[0]
        attribute = hash.keys[0].to_sym
        query = hash.values[0]
      else
        attribute = ""
        query = ""
      end
    end

    query = query
    @target_path = get_target_path

    begin
      f = File.open("#{@target_path}index.json", "rb")
    rescue
      generate_index_file
      f = File.open("#{@target_path}index.json", "rb")
    end

    index_json = f.read
    index_array = JSON.parse(index_json)
    results = []

    index_array.each do |ex|
      if (!@COLLECTION_KEYS.include? attribute.to_sym) &&
        ex[attribute.to_s] == query
        results << ex
      elsif (@COLLECTION_KEYS.include? attribute.to_sym) &&
        if query.class == String
          if ( ex[attribute.to_s] & query.split(/\,\s+/) != [] )
            results << ex
          end
        else
          if ( ex[attribute.to_s] & query != [] )
            results << ex
          end
        end
      end
    end

    prompt_user_with("RESULTS!")
    results.each.with_index(1) do |result, index|
      puts "Choice \##{index}: #{result['title']}"
    end

    puts "\nFound #{results.length} matches for a(n) '#{attribute.to_s}' with '#{query}'.\n"

    if search_results_prompt(results, query, attribute)
      search_for_exercise
    end
  end

  def generate_index_file
    @target_path = get_target_path
    exercises = []

    Dir.glob("#{@target_path}ex_*").each do |file_path|
      file = File.open("#{file_path}/meta.json", "rb")
      file_json = file.read
      file_hash = JSON.parse(file_json)
      exercises.push(file_hash)
      file.close
    end

    index_file = File.open("#{@target_path}index.json", "w")
    index_file.puts JSON.pretty_generate(exercises)
    index_file.close
  end

  def get_target_path
    unless @target_directory
      instructor_repo = get_target_path_from_config

      if instructor_repo
        puts "\nYour .wdi/config says that your current instructor repo is:\n"
        puts instructor_repo
        puts "\nIs that also the location of your exercises? (y)es or (n)o"
        choice = $stdin.gets.chomp
        if choice == "y"
          @target_directory = instructor_repo
        else
          puts "\nWhat is the path of your exercises directory (NO RELATIVE PATHS)?:"
          @target_directory = $stdin.gets.chomp
        end
      elsif @COMMAND_LINE_MODE
        @target_directory = Dir.pwd
      else
        puts "\nYou seem to be running this script from:\n"
        puts Dir.pwd
        puts "\nIs that also the location of your exercises? (y)es or (n)o"
        choice = $stdin.gets.chomp
        if choice == "y"
          @target_directory = Dir.pwd
        else
          puts "\nWhat is the path of your exercises directory (NO RELATIVE PATHS)?:"
          @target_directory = File.expand_path($stdin.gets.chomp)
        end
      end
    end

    if Dir[@target_directory] == []
      Dir.mkdir(@target_directory)
    end

    @target_path = "#{@target_directory}#{@target_directory[-1] != '/' ? '/' : ''}"

    return @target_path
  end

  def get_target_path_from_config
    if File.exists? WDI_CONFIG_FILE
      return JSON.parse(IO.read(File.expand_path(WDI_CONFIG_FILE)))["instructor_repos"]["current"]
    else
      return nil
    end
  end

  def get_attribute_of_exercise
    puts "What exercise attribute do you want to search by?"

    puts <<-EOS
        1. id
        2. language
        3. tags
        4. authors
        5. level
        6. length
        7. unit
        8. lesson_name
    EOS

    choice = $stdin.gets.chomp.to_i

    attribute = {
      1 => :id,
      2 => :language,
      3 => :tags,
      4 => :authors,
      5 => :level,
      6 => :length,
      7 => :unit,
      8 => :lesson_name
    }[choice]

    if attribute.nil?
      prompt_user_with("Please enter valid attribute!")
      return get_attribute_of_exercise()
    else
      return attribute
    end
  end

  def search_results_prompt(results, query, attribute)
    puts <<-EOS.gsub(/^\s*/, "")
      What do you want to do?

      - you can type the choice number to open its readme
      - type "q" to quit search mode.
      #{ !@COMMAND_LINE_MODE ? '- type "s" to search again' : '' }
    EOS

    choice = $stdin.gets.chomp

    case choice
    when "q"
      return false
    when "s"
      unless @COMMAND_LINE_MODE
        return true
      else
        search_for_exercise
      end
    else
      if results[choice.to_i-1]
        system("open #{@target_path}ex_#{results[choice.to_i-1]['id']}/README.md")
        system("open #{@target_path}ex_#{results[choice.to_i-1]['id']}")
        search_results_prompt(results, nil, nil)
      else
        prompt_user_with("Invalid Choice!")
        search_results_prompt(results, nil, nil)
      end
    end
  end

  def assign_learning_objective(unit)
    unit_array = unit.split(".")
    unit_num = unit_array[0].to_i
    lesson_num = unit_array[1].to_i
    curriculum_meta = get_curriculum_meta(unit_num, lesson_num)
    return curriculum_meta["learning_objective"] || ""
  end

  def get_curriculum_meta(unit_num, lesson_num)
    return {} if @CURRICULUM.empty?
    @CURRICULUM["units"][unit_num]["lessons"].select do |lesson|
      lesson["number"] == "#{unit_num}.#{lesson_num}".to_f
    end.first()
  end

  def parse_argv(arguments)
    meta_hash = {}
    arguments.each_index do |index|
      key_val_string = arguments[index]
      key_val_array = key_val_string.split(":")
      key = key_val_array[0]
      value = key_val_array[1]
      if @COLLECTION_KEYS.include? key.to_sym
        meta_hash[key] = value.split(",")
      else
        meta_hash[key] = value
      end
    end
    return meta_hash
  end

  def prompt_user_with(message)
    delimiter = "=" * message.size

    puts <<-EOS.gsub(/^\s*/, "")
    #{delimiter}
    #{message}
    #{delimiter}
    EOS
  end

end

Folgers.new

# vim: set sw=2 sts=2:
