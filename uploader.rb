require "rest-client"
require "json"
require "./authoriser.rb"

class Uploader # uploads files and folders to an authorised Google Drive account
  def initialize # prompts user to authorise a Google Drive account and creates resources
    authoriser = Authoriser.new
    authoriser.authorise # prompts user to authorise their account
    @access_token = authoriser.get_access_token # saves generated access token
    @drive_manager = RestClient::Resource.new("https://www.googleapis.com/drive/v3/files/",
                                              :headers => {"Authorization" => "Bearer #{@access_token}",
                                                           "Content-Type" => "application/json"})
    @drive_uploader = RestClient::Resource.new("https://www.googleapis.com/upload/drive/v3/files",
                                               :headers => {"Authorization" => "Bearer #{@access_token}"})
    @folder_ids_hash = {}
    @failed_uploads = [] # list of failed uploads which is returned at end
  end

  def upload_filesystem(filesystem_path, filesystem_name)
    root_id = upload_root(filesystem_name)
    @folder_ids_hash[filesystem_path.chomp("/")] = root_id
    upload_directory(upload_dest: root_id, current_dir: filesystem_path)
  end

  def upload_directory(upload_dest: "root", current_dir: "") # recursively uploads a filesystem
    Dir[current_dir + "*"].each do |object| # does not return hidden objects
      if object.include?(".") # checks if object is a file
        file_name = object.split("/")[-1]
        p file_name
        file_id = upload_file(object, file_name, location: upload_dest)
      else
        folder_name = object.split("/")[-1]
        p folder_name
        folder_id = upload_folder(folder_name, location: upload_dest)
        @folder_ids_hash[object] = folder_id
        upload_directory(upload_dest: folder_id, current_dir: current_dir + folder_name + "/")
      end
    end
  end

  def upload_folder(folder_name, hex_colour: "#A2FF33", location: "root") # uploads a folder with optional colour
    begin
      upload = @drive_manager.post(
        {"name" => folder_name,
         "mimeType" => "application/vnd.google-apps.folder",
         "folderColorRgb" => hex_colour}.to_json)
    rescue => error
      p error
    end

    folder_id = JSON.parse(upload)["id"]

    if location != "root" # does not need to change parents if intended location is root
      begin
        move = @drive_manager[folder_id + "?addParents=" + location + "&removeParents=root&alt=json"].patch(
          {"uploadType" => "resumable"}.to_json)
      rescue => error
        p error
      end
    end

    return folder_id
  end

  def upload_file(file_path, file_name, location: "root")
    begin
      payload = File.open(file_path)
    rescue => error
      p error
    end

    begin
      upload = @drive_uploader.post(
        payload)
    rescue
      @failed_uploads.push(file_path) # needs testing
      puts "Failed to upload " + file_path
    end

    file_id = JSON.parse(upload)["id"]

    begin
      rename = @drive_manager[file_id + "?addParents=" + location + "&removeParents=root&alt=json"].patch( # changes file name and puts in folder
        {"uploadType" => "resumable",
         "name" => file_name}.to_json)
    rescue
      p error
    end

    return file_id
  end

  def update_file_permission(file_id, email)
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

  def get_failed_uploads
    return @failed_uploads
  end

  def get_folder_ids
    return @folder_ids_hash
  end

  def upload_root(root_name)
    root_id = upload_folder(root_name)
    return root_id
  end
end
