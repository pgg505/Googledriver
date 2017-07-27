require "rest-client"
require "json"
require "./authorizer.rb"

class Uploader
  def initialize
    @TOKEN_LIFETIME = 3600 # time in seconds before access token is made void
    @file_ids = {} # hash of files to ids
    @folder_ids = {} # hash of folders to ids
    @authorizer = Authorizer.new
    @access_token = @authorizer.access_token
    @refresh_token = @authorizer.refresh_token
    update_rest_clients
  end

  def update_rest_clients
    @drive_manager = RestClient::Resource.new("https://www.googleapis.com/drive/v3/files/",
                                              :headers => {"Authorization" => "Bearer #{@access_token}",
                                                           "Content-Type" => "application/json"})
    @drive_uploader = RestClient::Resource.new("https://www.googleapis.com/upload/drive/v3/files",
                                               :headers => {"Authorization" => "Bearer #{@access_token}"})
  end

  def upload_filesystem(upload_dest: "root", current_dir: "") # recursively uploads a filesystem
    Dir[current_dir + "*"].each do |object| # does not return hidden objects
      if object.include?(".") # checks if object is a file
        file_name = object.split("/")[-1]
        file_id = upload_file(object, file_name, location: upload_dest)
        @file_ids[object] = file_id
      else
        folder_name = object.split("/")[-1]
        folder_id = upload_folder(folder_name, location: upload_dest)
        @folder_ids[object] = folder_id
        upload_filesystem(upload_dest: folder_id, current_dir: current_dir + folder_name + "/")
      end
    end
  end

  def upload_folder(folder_name, location: "root", hex_colour: "#929292") # uploads a folder with optional colour
    if refresh?
      refresh_token
    end

    begin
      upload = @drive_manager.post(
        {"name" => folder_name,
         "mimeType" => "application/vnd.google-apps.folder",
         "folderColorRgb" => hex_colour}.to_json)
    rescue Exception
      puts "upload_folder error 1"
    end

    folder_id = JSON.parse(upload)["id"]

    if location != "root" # does not need to change parents if intended location is root
      if refresh?
        refresh_token
      end

      begin
        move = @drive_manager[folder_id + "?addParents=" + location + "&removeParents=root&alt=json"].patch(
          {"uploadType" => "resumable"}.to_json)
      rescue Exception
        puts "upload_folder error 2"
      end
    end

    return folder_id
  end

  def upload_file(file_path, file_name, location: "root")
    if refresh?
      refresh_token
    end

    begin
      payload = File.open(file_path)
    rescue Exception
      puts "upload_file error 1"
    end

    if refresh?
      refresh_token
    end

    begin
      upload = @drive_uploader.post(
        payload)
    rescue Exception
      puts "upload_file error 2"
    end

    file_id = JSON.parse(upload)["id"]

    if refresh?
      refresh_token
    end

    begin
      rename = @drive_manager[file_id + "?addParents=" + location + "&removeParents=root&alt=json"].patch( # changes file name and puts in folder
        {"uploadType" => "resumable",
         "name" => file_name}.to_json)
    rescue Exception
      puts "upload_folder error 3"
    end

    return file_id
  end

  def file_ids
    return @file_ids
  end

  def folder_ids
    return @folders_ids
  end

  def refresh?
    token_timer = Time.now - @authorizer.token_tob

    if token_timer > (@TOKEN_LIFETIME - 600)
      return true
    else
      return false
    end
  end

  def refresh_token
    @authorizer.generate_access_token
    @access_token = @authorizer.access_token
    p update_rest_clients
  end
end
