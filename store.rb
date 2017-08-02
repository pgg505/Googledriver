def obtain_hrefs
  temp_string = @doc.css('ul.menu.nav').css('a')
  hrefs = temp_string
  hrefs
end

def process_links(hrefs, links)
  processed_links = []
  index = 0

  links.each do |link|
    link_data = [] # contains metadata and link text for each link on page
    link_data.push(link.to_s.split('class="')[1].split('"')[0])
    link_data.push(hrefs[index].to_s.split('href="')[1].split('"')[0])
    link_data.push(hrefs[index].text)
    processed_links.push(link_data)
    index += 1
  end

  processed_links
end

def finalise_links(processed_links)
  finalised_links = []

  processed_links.each do |processed_link|
    link_data = []
    active = false
    level = processed_link[0].to_s.split('level-')[1]

    if level.include?('active')
      active = true
      level = level.chomp(' active')
    end

    link_data.push(level)
    link_data.push(active)
    link_data.push(processed_link[1])
    link_data.push(processed_link[2])
    finalised_links.push(link_data)
  end

  finalised_links
end

def update_file_permission(file_id, email) # shares a given file or folder with a single email address
  if refresh?
    refresh_token
  end

  payload = {"role" => "writer",
             "type" => "group",
             "emailAddress" => email}.to_json

  begin
    update = @drive_manager[file_id + "/permissions"].post(
      payload)
  rescue => error
    p error
  end

  return update
end

class Mandator
  def initialize # initialises hashes
    @groups_to_email = {}
    @folders_to_htaccess = {}
  end

  def mandate # builds hashes
    build_groups_to_email("groups.txt") # for a file in the same directory as code
    build_folders_to_htaccess(starting_dir: "elecint0/documents/") # change this to match upload directory
  end

  def build_groups_to_email(file_path)
    file_contents = File.read(file_path).split("\n")

    file_contents.each do |mapping|
      if mapping[0] != "#"
        group = mapping.split("=>")[0]
        email = mapping.split("=>")[1]
        @groups_to_email[group] = email
      end
    end
  end

  def get_groups_to_email
    return @groups_to_email
  end

  def build_folders_to_htaccess(starting_dir: "")
    Dir[starting_dir + "**/.htaccess"].each do |object|
      file_contents = File.read(object).split("\n")
      permissions = []
      require_lines = []

      file_contents.each do |element|
        if element.include?("Require")
          permissions.push(element.split(" ").drop(2))
        end
      end

      if permissions.any?
        permissions = permissions.flatten
        emails = []

        permissions.each do |permission|
          emails.push(@groups_to_email[permission])
        end

        @folders_to_htaccess[object.chomp("/.htaccess")] = emails
      end
    end
  end

  def get_folders_to_htaccess
    return @folders_to_htaccess
  end
end

def get_file_metadata(file_id)
  '''(String) -> String. Returns the metadata of a given file.'''

  begin
    metadata = RestClient.get(
      "https://www.googleapis.com/drive/v3/files/" + file_id,
      {"Authorization" => "Bearer #{@access_token}"})
  rescue => error
    p error
  end

  metadata = JSON.parse(metadata)
  return metadata
end

def get_file_permissionid(file_id)
  '''(String) -> String. Returns the permission ID of a given file.'''

    clean_metadata = get_file_metadata(file_id).split("permissionId")[1].split("\n")[0]
    permission_id = clean_metadata.gsub(/[,:"\ ]/, "")
    return permission_id
end

def get_file_permission(file_id, permission_id)
  begin
    permission = RestClient.get(
      "https://www.googleapis.com/drive/v3/files/" + file_id + "/permissions/" + permission_id,
      {"Authorization" => "Bearer #{@access_token}"}
      )
  rescue => error
    p error
  end

  return permission
end

def update_file_metadata(file_id, element, new_data)
  '''(String, String, String) -> String. For a given file and data element, updates that piece of metadata.'''

  begin
    payload = {"uploadType" => "resumable", element => new_data}.to_json()
    update = RestClient.patch(
      "https://www.googleapis.com/drive/v3/files/" + file_id,
      payload,
      {"Authorization" => "Bearer #{@access_token}",
       "Content-Type" => "application/json"}
      )
  rescue => error
    p error
  end

  return update
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
