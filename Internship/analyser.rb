#!/usr/bin/ruby

def where_is_package(package_name)
  '''(String) -> String. Returns the location of a given package. Returns "package_name:" if package is not installed.'''

  system( "whereis " + package_name + "> 'packageLocation.txt'" ) # system() executes Bash command and returns boolean
  f = File.new("packageLocation.txt", "r")
  location = File.read(f)
  return location
end

def does_package_exist(package_name)
  '''(String) -> Boolean. Returns true if package is installed else returns false.'''

  if where_is_package(package_name) == package_name + ":\n"
    return false
  else
    return true
  end
end

def install_tree()
  '''() -> Void. Installs Tree if it is not already on the system else does nothing.'''

  if does_package_exist("tree") == false
    begin
      system( "sudo apt-get install tree" ) # assumes that this command for installing Tree will not change
    rescue
      puts "The Tree package could not be automatically installed. Please install Tree manually and rerun program."
    end
  end
end

def get_tree_structure()
  '''() -> Void. Uses working directory as root and creates tree strucutre of directory.'''

  begin
    system( "tree -a > diretoryStructure.txt" )
  rescue
    puts "The file directoryStructure.txt could not be created. Please create the file manually and rerun program."
  end
end

def init()
  install_tree()
  get_tree_structure()
end

init()
