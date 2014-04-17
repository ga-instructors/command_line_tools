require 'json'

require 'folgers/ui'

WDI_CONFIG_DIR = "#{ENV['HOME']}/.wdi"
WDI_CONFIG_FILE = "#{WDI_CONFIG_DIR}/config.json"
WDI_CURRICULUM_FILE = "#{WDI_CONFIG_DIR}/curriculum.json"
WDI_STUDENTS_FILE = "#{WDI_CONFIG_DIR}/students.json"

module Folgers

  COLLECTION_KEYS = [:contributors, :languages, :authors, :tags]

  class Folgers

    attr_reader :config

    def initialize
      @curriculum = try_load_file(WDI_CURRICULUM_FILE)
      @students = try_load_file(WDI_STUDENTS_FILE)

      if File.exists? WDI_CONFIG_FILE
        @config = JSON.parse(File.read(File.expand_path(WDI_CONFIG_FILE)))
      else
        @config = {}
      end
    end

    def current_instructor_repo
      if @config['instructor_repos']
        return @config['instructor_repos']['current']
      else
        return nil
      end
    end

    def try_load_file(filename)
      if File.exists? filename
        return File.open(filename, "rb")
      else
        prompt_user_with("No #{filename} found! Certain features may not work.")
        return []
      end
    end

    def test_student_files(options=nil)
      valid_options = ["v", "-v", "verbose"]
      fails = []
      Dir.glob("./*/*_spec.rb").each do |file|
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
        unless ignored_files.include? file.to_s
          system("cp -R #{assignment_dir}/* #{file}")
          puts "Distributed #{assignment_dir} to #{file}"
        end
      end
      nil
    end

    def make_student_folders(target_path)
      error("Must specify folder name!") unless target_path

      target_folder_name = target_path.gsub(/[\s|\/]/,"")
      new_dir_path = "#{Dir.pwd}/#{target_folder_name}"

      begin
        Dir.mkdir(new_dir_path)
      rescue Exception => e
        unless e.class == Errno::EEXIST
          return
        end
      end

      puts "Making Student Folders"

      @students.each do |student|
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

    def make_new_exercise(target_path)
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

      exercise_directory = "#{target_path}/ex_#{id}"

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

      generate_index_file(target_path)
    end

    def make_new(target_path, resource)
      if resource != "meta"
        error "Sorry, only the 'meta' resource type is supported right now."
      end

      id = Time.now.to_i

      new_meta_file_path = [
        target_path,
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

    def search_for_exercise(target_path, query, attribute)
      begin
        f = File.open("#{target_path}index.json", "rb")
      rescue
        generate_index_file(target_path)
        f = File.open("#{target_path}index.json", "rb")
      end

      index_json = f.read
      index_array = JSON.parse(index_json)
      results = []

      index_array.each do |ex|
        if (!COLLECTION_KEYS.include? attribute.to_sym) &&
          ex[attribute.to_s] == query
          results << ex
        elsif (COLLECTION_KEYS.include? attribute.to_sym) &&
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
    end

    def generate_index_file(target_path)
      exercises = []

      Dir.glob("#{target_path}ex_*").each do |file_path|
        file = File.open("#{file_path}/meta.json", "rb")
        file_json = file.read
        file_hash = JSON.parse(file_json)
        exercises.push(file_hash)
        file.close
      end

      index_file = File.open("#{target_path}index.json", "w")
      index_file.puts JSON.pretty_generate(exercises)
      index_file.close
    end

    def assign_learning_objective(unit)
      unit_array = unit.split(".")
      unit_num = unit_array[0].to_i
      lesson_num = unit_array[1].to_i
      curriculum_meta = get_curriculum_meta(unit_num, lesson_num)
      return curriculum_meta["learning_objective"] || ""
    end

    def get_curriculum_meta(unit_num, lesson_num)
      return {} if @curriculum.empty?
      @curriculum["units"][unit_num]["lessons"].select do |lesson|
        lesson["number"] == "#{unit}.#{lesson_num}".to_f
      end.first()
    end

    def prompt_user_with message
      UI.prompt_user_with message
    end

    private

    def error message
      prompt_user_with message
      exit 1
    end

  end

end

# vim: set sw=2 sts=2:
