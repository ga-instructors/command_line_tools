require 'json'

def main_menu
  puts <<-EOS
====================================
====================================
====================================
====================================
       {
    {   }
     }_{ __{
  .-{   }   }-.
 (   }     {   )
 |`-.._____..-'|
 |             ;--.
 |             (__  \
 |             | )  )
 |             |/  /
 |             /  /
 |             (  /
 \             y'
  `-.._____..-'
====================================
====================================
====================================
====================================
                        
    What would you like to do? 

    1. make new exercise       
    2. quit                    

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
      system("clear")
      puts <<-EOS
================================
========== GOODBYE! ============
================================
EOS
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
  unless $target_directory
    puts "what is the path of your exercises directory (NO RELATIVE PATHS)?:"
    $target_directory = gets.chomp
  end
  id = Time.now.to_i
  puts "enter the title: "
  title = gets.chomp
  puts "enter the language: "
  language = gets.chomp
  puts "enter the author(s) (i.e. firstname lastname separated by commas): "
  authors = gets.chomp.split(/\,\s+/)
  puts "enter tags (separated by spaces): "
  tags = gets.chomp.split(/\s+/)
  puts "enter difficulty level (1-10, 10 being hardest): "
  level = gets.chomp.to_i

  if Dir[$target_directory] == []
    Dir.mkdir($target_directory)
  end

  target_path = "#{$target_directory}#{$target_directory[-1] != '/' ? '/' : ''}"

  exercise_directory = "#{target_path}/ex_#{id}"

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
    level: level
  }

  f.puts JSON.pretty_generate(meta_hash)

  f.close
end

main_menu