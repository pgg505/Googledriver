class Analyser
  '''Analyses an Ubuntu file system.'''

  def initialize()
    Dir['**/*'].each { |f| print f + "\n" }
    #install_tree()
    #install_awk()
    #get_tree_structure()
    #edit_tree_structure()
    #analyse_tree_strucutre()
  end

  def where_is_package(package_name)
    '''(String) -> String. Returns the location of a given package. Returns "package_name:" if package is not installed.'''

    system( "whereis " + package_name + "> packageLocation.txt" )
    f = File.new("packageLocation.txt", "r")
    location = File.read(f)
    return location
  end

  def does_package_exist(package_name)
    '''(String) -> Boolean. Returns true if package is installed else returns false.'''

    if where_is_package(package_name) == package_name + ":\n" then
      return false
    else
      return true
    end
  end

  def install_tree()
    '''() -> Void. Installs Tree if it is not already on the system else does nothing.'''

    if does_package_exist("tree") == false then
      begin
        system( "sudo apt-get install tree" ) # assumes that this command for installing Tree will not change
      rescue
        puts "The Tree package could not be automatically installed. Please install Tree manually and rerun program."
      end
    end
  end

  def install_awk()
    '''() -> Void. Installs Awk if it is not already on the system else does nothing.'''

    if does_package_exist("awk") == false then
      begin
        system( "sudo apt-get install awk" ) # assumes that this command for installing Tree will not change
      rescue
        puts "The Tree package could not be automatically installed. Please install Awk manually and rerun program."
      end
    end
  end

  def get_tree_structure()
    '''() -> Void. Uses working directory as root and creates tree strucutre of directory.'''

    begin
      system( "tree -a > uneditedStruc.txt" ) # displays all files and folders
    rescue
      puts "The file uneditedStruc.txt could not be created. Please create the file manually and rerun program."
    end
  end

  def edit_tree_structure()
    '''() -> Void. Edits the file uneditedStruc.txt and puts contents in editedStruc.txt'''

    begin
      system( "awk '{sub(/└──/,\"├──\")}1' uneditedStruc.txt > editedStruc.txt" )
    rescue
      puts "The file editedStruc.txt could not be created. Please create the file manually and rerun program."
    end
  end

  def analyse_tree_strucutre()
    '''() -> Void. Makes another file with useful directory information.'''

    File.readlines("editedStruc.txt").each() do |line|
      if (line[0] == "│") || (line[0] == "├") then # ignores first and last lines
        begin
          temp_str = line.split("├──")[0]
          layer = temp_str.count("│") # can be zero
          name = line.split("├──")[1].strip()
          p layer.to_s() + "-" + name
        rescue => error
          p error
        end
      end
    end
  end
end
