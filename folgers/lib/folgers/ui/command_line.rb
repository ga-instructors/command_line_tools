require 'folgers/ui'

module Folgers::UI

  module CommandLine

    def self.run argv
      parse_arguments argv
    end

    def self.parse_arguments argv
      puts "You chose: #{option}"

      if (option == "g" || option == "generate")
        puts "Made: "
        puts make_new(argv.shift)

      elsif (option == "f" || option == "folders")
        puts make_student_folders(argv.shift)

      elsif (option == "d" || option == "distribute")
        puts distribute_to_students(argv.shift)

      elsif (option == "s" || option == "search")
        puts "Finding"
        search_for_exercise(argv)

      elsif (option == "t" || option == "test")
        # TODO: Max must improve this
        puts test_student_files(argv.shift)
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

      folgers.search_for_exercise(query, attribute)
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

  end

end

# vim: set sw=2 sts=2:
