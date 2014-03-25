require 'json'
require 'pry'

def start
  option = ARGV.shift
  if option.nil?
    main_menu
  else
    puts "You chose: #{option}"
    if (option == "g" || option == "generate")
      puts "Made: "
      puts make_new(ARGV.shift)
    else
      prompt_user_with("Invalid Input!")
    end
      
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
    4. quit                    

EOS
  choice = gets.chomp.to_i
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

def make_new_exercise
  $target_path = get_target_path
  
  id = Time.now.to_i

  puts "enter the title: "
  title = gets.chomp
  puts "enter the language: "
  language = gets.chomp
  puts "enter the author(s) (i.e. firstname lastname separated by commas): "
  authors = gets.chomp.split(/\,\s+/)
  puts "enter tags (separated by spaces): "
  tags = gets.chomp.split(/\s+/)
  # puts "enter difficulty level (1-10, 10 being hardest): "
  # level = gets.chomp.to_i
  puts "enter the unit number (i.e. 3.14): "
  unit = gets.chomp
  puts "enter the length of the exercise (i.e. 'short', 'long', 'drill'): "
  length = gets.chomp

  exercise_directory = "#{$target_path}/ex_#{id}"

  # make EX directory 
  Dir.mkdir(exercise_directory)

  # make a solutions dir
  Dir.mkdir("#{exercise_directory}/solutions")

  # make a starters dir
  Dir.mkdir("#{exercise_directory}/starters")

  readme_string = <<-EOS
\##{title}

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
    length: length
  }

  f.puts JSON.pretty_generate(meta_hash)

  f.close

  generate_index_file
end

def make_new(resource)

  # TODO: support more types of resources
  return false if resource != "meta"

  $target_path = Dir.pwd
  
  id = Time.now.to_i

  new_meta_file_path = [ 
      $target_path,
      "/meta.json"
      ].join("")

  f = File.open(new_meta_file_path, "w")

  # TODO: turn the building of this hash into its own function
  meta_hash = {}
  meta_hash["id"] = id

  while !ARGV.empty? 
    key_val_string = ARGV.shift
    key_val_array = key_val_string.split(":")
    key = key_val_array[0]
    value = key_val_array[1]
    collection_keys = ["tags", "contributors", "languages"]
    if collection_keys.include? key 
      meta_hash[key] = value.split(",")
    else 
      meta_hash[key] = value
    end
  end

  # binding.pry
  f.puts JSON.pretty_generate(meta_hash)

  f.close
  return meta_hash
end

def search_for_exercise
  
  attribute = get_attribute_of_exercise

  puts "enter your search query:"
  query = gets.chomp

  $target_path = get_target_path

  begin 
    f = File.open("#{$target_path}index.json", "rb")
  rescue
    generate_index_file
    f = File.open("#{$target_path}index.json", "rb")
  end
  index_json = f.read
  index_array = JSON.parse(index_json)
  results = []
  # TODO: put this somewhere else
  attributes_that_are_collections = [:authors, :tags]
  index_array.each do |ex|
    if (!attributes_that_are_collections.include? attribute) &&
      ex[attribute.to_s] == query
      results << ex
    elsif (attributes_that_are_collections.include? attribute) && 
      (ex[attribute.to_s] & query.split(/\,\s+/) != [] )
      results << ex
    end
  end

  prompt_user_with("RESULTS!")
  results.each.with_index(1) do |result, index|
    puts "Choice \##{index}: #{result['title']}"
  end
  puts "\nFound #{results.length} matches for a(n) '#{attribute.to_s}' with '#{query}'.\n"
  if search_results_prompt(results)
    search_for_exercise
  end
end

def generate_index_file
  $target_path = get_target_path
  exercises = []
  Dir.glob("#{$target_path}ex_*").each do |file_path|
    file = File.open("#{file_path}/meta.json", "rb")
    file_json = file.read
    file_hash = JSON.parse(file_json)
    exercises.push(file_hash)
    file.close
  end
  index_file = File.open("#{$target_path}index.json", "w")
  index_file.puts JSON.pretty_generate(exercises)
  index_file.close
end

def get_target_path

  unless $target_directory
    puts "\nYou seem to be running this script from:\n"
    puts Dir.pwd
    puts "\nIs that also the location of your exercises? (y)es or (n)o"
    choice = gets.chomp
    if choice == "y"
      $target_directory = Dir.pwd
    else
      puts "\nWhat is the path of your exercises directory (NO RELATIVE PATHS)?:"
      $target_directory = gets.chomp
    end
    
  end

  if Dir[$target_directory] == []
    Dir.mkdir($target_directory)
  end

  $target_path = "#{$target_directory}#{$target_directory[-1] != '/' ? '/' : ''}"
  return $target_path
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
  choice = gets.chomp.to_i
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

def search_results_prompt(results)
  puts <<-EOS

What do you want to do?

- you can type the choice number to open its readme
- type "q" to return the main menu"
- type "s" to search again

  EOS
  choice = gets.chomp
  case choice
  when "q"
    return false
  when "s"
    return true
  else
    if results[choice.to_i-1] 
      system("open #{$target_path}ex_#{results[choice.to_i-1]['id']}/README.md")
      search_results_prompt(results)
    else 
      prompt_user_with("Invalid Choice!")
      search_results_prompt(results)
    end
  end
end

def prompt_user_with(message)
  puts <<-EOS
***************************
#{message}
***************************
  EOS
end

start