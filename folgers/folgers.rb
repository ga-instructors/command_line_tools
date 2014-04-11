require 'json'
require 'pry'

class Folgers

  def initialize

    # GLOBALS
    @COLLECTION_KEYS = [ :contributors, :languages, :authors, :tags]
    @COMMAND_LINE_MODE = false
    @ORIGINAL_OPTIONS = ARGV

    set_curriculum
    set_student_roster

    option = ARGV.shift
    if option.nil?
      main_menu
    else
      @COMMAND_LINE_MODE = true
      puts "You chose: #{option}"
      if (option == "g" || option == "generate")
        puts "Made: "
        puts make_new(ARGV.shift)
      elsif (option == "f" || option == "folders")
        puts make_student_folders(ARGV.shift)
      elsif (option == "s" || option == "search")
        puts "Finding"
        search_for_exercise
      end
        
    end
  end

  def set_curriculum
    begin
      curriculum_file = File.open("#{ENV['HOME']}/.wdi/curriculum.json", "rb")
      @CURRICULUM = JSON.parse(curriculum_file.read)
    rescue
      prompt_user_with("No ~/.wdi/curriculum.json found!  Certain features may not work")
      @CURRICULUM = []
    end
  end

  def set_student_roster
    begin
      student_roster_file = File.open("#{ENV['HOME']}/.wdi/students.json", "rb")
      @STUDENTS = JSON.parse(student_roster_file.read)
    rescue
      prompt_user_with("No ~/.wdi/students.json found!  Certain features may not work")
      @STUDENTS = []
    end
  end

  def main_menu
    puts <<-EOS




                 {
              {   }
               }_{ __{
            .-{   }   }-.
           (   }     {   )
           |`-.._____..-'|
           |             ;---.
           |             (__  \\
           |             |  )  )
           |             | /  /
           |             |/  /
           |             (  /
           \\              |'
            `-.._____..-'
    __       _                     
   / _| ___ | | __ _  ___ _ __ ___ 
  | |_ / _ \\| |/ _` |/ _ \\ '__/ __|
  |  _| (_) | | (_| |  __/ |  \\__ \\
  |_|  \\___/|_|\\__, |\\___|_|  |___/
               |___/ 
                          
      What would you like to do? 

      1. make new exercise   
      2. find an exercise
      3. generate index JSON  
      4. make student folders  
      5. quit                    

  EOS
    choice = $stdin.gets.chomp.to_i
    case choice
      when 1
        make_new_exercise
        system("clear")
        puts <<-EOS
  ================================
  ===== Created Successfully! ====
  ================================
  EOS
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
        puts <<-EOS
  ======================================
  ===== PLEASE ENTER A VALID OPTION ====
  ======================================
  EOS
        main_menu
    end
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
      name = student['Name'].gsub(/ $|\n/,"").gsub(/^ /,"").gsub(/ +/,"_")
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
    puts "Making Instructors Folder"
    Dir.mkdir("#{new_dir_path}/Instructors")
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
    # puts "enter difficulty level (1-10, 10 being hardest): "
    # level = $stdin.gets.chomp.to_i
    
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

    readme_string = <<-EOS
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

    # TODO: support more types of resources
    return false if resource != "meta"

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

    # binding.pry
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
      # attribute_query_string = ARGV.shift
      hash = parse_argv(@ORIGINAL_OPTIONS)
      # binding.pry
      if hash.keys[0]
        attribute = hash.keys[0].to_sym
        query = hash.values[0]
      else 
        attribute = ""
        query = ""
      end
      # binding.pry
    end
    # binding.pry
    query = query
    @target_path = get_target_path
      # binding.pry
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
    # binding.pry
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
      # PJ: do a quick search for the .wdi/config.json -- if found suggest that
      instructor_repo = get_target_path_from_config if File.exists?(File.expand_path("~/.wdi/config.json"))
      

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
      # for@command_line_mode
      end
        
    end
    if Dir[@target_directory] == []
      Dir.mkdir(@target_directory)
    end

    @target_path = "#{@target_directory}#{@target_directory[-1] != '/' ? '/' : ''}"
    return @target_path
  end

  def get_target_path_from_config
    JSON.parse(IO.read(File.expand_path("~/.wdi/config.json")))["instructor_repos"]["current"]
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
    case choice
    when 1
      attribute = :id
    when 2
      attribute = :language
    when 3
      attribute = :tags
    when 4
      attribute = :authors
    when 5
      attribute = :level
    when 6
      attribute = :length
    when 7
      attribute = :unit
    when 8
      attribute = :lesson_name
    else
      prompt_user_with("Please enter valid attribute!")
      attribute = get_attribute_of_exercise
    end
    return attribute
  end

  def search_results_prompt(results, query, attribute)
    puts <<-EOS

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
    return "" if @CURRICULUM.empty?
    unit_array = unit.split(".")
    unit_num = unit_array[0].to_i 
    lesson_num = unit_array[1].to_i
    curriculum_meta = @CURRICULUM["units"][unit_num]["lessons"].select { |lesson| lesson["number"] == "#{unit}.#{lesson_num}".to_f }.first
    if curriculum_meta
      return curriculum_meta["learning_objective"]
    else
      return ""
    end
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
    puts <<-EOS
  ***************************
  #{message}
  ***************************
    EOS
  end

end

Folgers.new