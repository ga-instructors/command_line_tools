require 'folgers/ui'

MAIN_MENU_FILE = File.expand_path("../main_menu.txt", __FILE__)

module Folgers::UI

  class Interactive

    def initialize(folgers)
      @folgers = folgers
    end

    def run
      choice = nil

      while choice != 5
        print_menu
        next_prompt = do_folgers($stdin.gets.chomp.to_i)
        system("clear")
        prompt_user_with(next_prompt) if next_prompt
      end
    end

    def print_menu
      print File.read(MAIN_MENU_FILE)
    end

    def do_folgers choice
      case choice
      when 1
        make_new_exercise
        return "Created successfully!"
      when 2
        search_for_exercise
      when 3
        @folgers.generate_index_file
      when 4
        make_student_folders
      else
        return "PLEASE ENTER A VALID OPTION"
      end

      return nil
    end

    def prompt_user_with message
      Folgers::UI.prompt_user_with message
    end

    def make_new_exercise
      id = Time.now.to_i
      target_path = get_target_path

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

      @folgers.make_new_exercise(target_path, id, unit, lesson_name, title, language, authors, tags, length)
    end

    def make_student_folders
      puts "What is the name of the student folder? (i.e. d01)"
      target_folder = gets.chomp

      @folgers.make_student_folders(target_folder)
    end

    def search_for_exercise
      attribute = get_attribute_of_exercise()
      target_path = get_target_path

      puts "enter your search query:"
      query = $stdin.gets.chomp

      search_until_user_quits(target_path, query, attribute)
    end

    def search_until_user_quits(target_path, query, attribute)
      results = @folgers.search_for_exercise(target_path, query, attribute)

      return false if !results

      if search_results_prompt(target_path, results, query, attribute)
        search_until_user_quits(target_path, query, attribute)
      end
    end

    def search_results_prompt(target_path, results)
      puts <<-EOS.gsub(/^\s*/, "")
        What do you want to do?

        - you can type the choice number to open its readme
        - type "q" to quit search mode.
        - type "s" to search again.
      EOS

      choice = $stdin.gets.chomp

      case choice
      when "q"
        return false
      when "s"
        return true
      else
        if results[choice.to_i-1]
          system("open #{target_path}ex_#{results[choice.to_i-1]['id']}/README.md")
        else
          prompt_user_with("Invalid Choice!")
        end

        return true
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

    def get_target_path
      instructor_repo = @folgers.current_instructor_repo

      if instructor_repo
        puts "\nYour .wdi/config says that your current instructor repo is:\n"
        puts instructor_repo
        puts "\nIs that also the location of your exercises? (y)es or (n)o"
        choice = $stdin.gets.chomp
        if choice == "y"
          target_directory = instructor_repo
        else
          puts "\nWhat is the path of your exercises directory (NO RELATIVE PATHS)?:"
          target_directory = $stdin.gets.chomp
        end
      else
        puts "\nYou seem to be running this script from:\n"
        puts Dir.pwd
        puts "\nIs that also the location of your exercises? (y)es or (n)o"
        choice = $stdin.gets.chomp
        if choice == "y"
          target_directory = Dir.pwd
        else
          puts "\nWhat is the path of your exercises directory (NO RELATIVE PATHS)?:"
          target_directory = File.expand_path($stdin.gets.chomp)
        end
      end

      if Dir[target_directory] == []
        Dir.mkdir(target_directory)
      end

      target_path = "#{target_directory}#{target_directory[-1] != '/' ? '/' : ''}"

      return target_path
    end

  end

end

# vim: set sw=2 sts=2:
