require 'folgers/ui'

module Folgers::UI

  class CommandLine

    def initialize(folgers)
      @folgers = folgers
    end

    def run(argv)
      result = parse_arguments(argv)
      puts results
    end

    def parse_arguments argv
      target_folder = Dir.pwd

      if (option == "g" || option == "generate")
        resource_type = argv.shift
        @folgers.make_new(target_folder, resource_type)

      elsif (option == "f" || option == "folders")
        @folgers.make_student_folders(target_folder)

      elsif (option == "d" || option == "distribute")
        @folgers.distribute_to_students(argv.shift)

      elsif (option == "s" || option == "search")
        query = argv.shift
        attribute = argv.shift
        @folgers.search_for_exercise(target_path, query, attribute)

      elsif (option == "t" || option == "test")
        @folgers.test_student_files(argv.shift)

      end
    end

    def search_for_exercise argv
      hash = parse_argv(argv)
      if hash.keys[0]
        attribute = hash.keys[0].to_sym
        query = hash.values[0]
      else
        attribute = ""
        query = ""
      end

      @folgers.search_for_exercise(query, attribute)
    end

    def parse_argv(arguments)
      meta_hash = {}
      arguments.each_index do |index|
        key_val_string = arguments[index]
        key_val_array = key_val_string.split(":")
        key = key_val_array[0]
        value = key_val_array[1]
        if Folgers::COLLECTION_KEYS.include? key.to_sym
          meta_hash[key] = value.split(",")
        else
          meta_hash[key] = value
        end
      end
      return meta_hash
    end

  end

end

# vim: set sw=2 sts=2:
