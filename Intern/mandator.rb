class Mandator # checks the permissions for folders in a filesystem
  def initialize
    @folder_access_hash = {}
    @groups_email_hash = {}
  end

  def build_htaccess_hash(starting_dir: "")
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
        @folder_access_hash[object.chomp("/.htaccess")] = permissions.flatten # set to match uploaded folder names
      end
    end

    p @folder_access_hash
  end

  def build_groups_hash(groups_file_path)
    groups_content = File.read(groups_file_path).split("\n")

    groups_content.each do |mapping|
      group = mapping.split("=>")[0]
      email = mapping.split("=>")[1]
      @groups_email_hash[group] = email
    end

    p @groups_email_hash  
  end
end
