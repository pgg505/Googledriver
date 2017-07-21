class Mandator # checks the permissions for folders in a filesystem
  def initialize
    @folder_access_hash = {}
  end

  def build_hash(starting_dir: "")
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
        @folder_access_hash[object] = permissions
      end
    end
    @folder_access_hash.each do |permission|
      p permission
    end
  end
end
