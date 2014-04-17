require 'folgers/ui'

MAIN_MENU_FILE = File.expand_path("../main_menu.txt", __FILE__)

module Folgers::UI

  module Interactive

    def self.run
      choice = nil

      print_menu

      while choice != 5
        choice = $stdin.gets.chomp.to_i
        do_folgers(choice)
      end
    end

    def self.print_menu
      print File.read(MAIN_MENU_FILE)
    end

    def self.do_folgers choice
      f = Folgers::Folgers.new

      case choice
      when 1
        f.make_new_exercise
        system("clear")
        prompt_user_with("Created Successfully!")
      when 2
        f.search_for_exercise
        system("clear")
      when 3
        f.generate_index_file
      when 4
        make_student_folders(f)
      when 5
        system("clear")
      else
        system("clear")
        prompt_user_with("PLEASE ENTER A VALID OPTION")
      end
    end

    def self.prompt_user_with message
      Folgers::UI.prompt_user_with message
    end

    def self.make_student_folders folgers
      puts "What is the name of the student folder? (i.e. d01)"
      target_folder = gets.chomp

      folgers.make_student_folders(target_folder)
    end

    def self.search_for_exercise folgers
      attribute = get_attribute_of_exercise

      puts "enter your search query:"
      query = $stdin.gets.chomp

      folgers.search_for_exercise(query, attribute)
    end

    def self.get_attribute_of_exercise
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

  end

end

# vim: set sw=2 sts=2:
