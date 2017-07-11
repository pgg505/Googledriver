#!/usr/bin/ruby

'''Remember that all files will be created in same directory as Ruby file.'''

def whereIsPackage(packageName)
  '''(String) -> String. Returns the location of a given package. Returns "packageName:" if package is not installed.'''

  system( "whereis " + packageName + "> 'packageLocation.txt'" ) # system() executes Bash command and returns boolean
  f = File.new("packageLocation.txt", "r")
  location = File.read(f)
  return location
end

def doesPackageExist(packageName)
  '''(String) -> Boolean. Returns true if package is installed and false if not.'''

  if whereIsPackage(packageName) == packageName + ":\n"
    return false
  else
    return true
  end
end

def installTree()
  '''() -> Void. Installs Tree if it is not already on the system else does nothing.'''

  if doesPackageExist("tree") == false
    begin
      system( "sudo apt-get install tree" ) # assumes that this command for installing Tree will not change
    rescue
      puts "The Tree package could not be automatically installed. Please install Tree manually and rerun program."
    end
  end
end

def getTreeStructure()
  '''() -> Void. Uses working directory as root to create tree strucutre of directory.'''

  begin
    system( "tree -a > diretoryStructure.txt" )
  rescue
    puts "Given directory is invalid. Please try again with a valid directory."
  end
end

def init()
  installTree()
  getTreeStructure()
end

init()
