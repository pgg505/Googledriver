require "rest-client"
require "json"
require "./authorizer.rb"

class Uploader
  def initialize
    @REFRESH_COOLDOWN = 3000 # time in seconds before access token is refreshed
    @file_ids = {} # file to ID hash
    @folder_ids = {} # folder to ID hash
    @authorizer = Authorizer.new
    @authorizer.authorize # prompts user to authorize their account if need be
    refresh_token
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

    begin
      upload = @drive_uploader.post(
        payload)
    rescue Exception
      puts "upload_file error 2"
    end

    file_id = JSON.parse(upload)["id"]

    begin
      rename = @drive_manager[file_id + "?addParents=" + location + "&removeParents=root&alt=json"].patch( # changes file name and puts in folder
        {"uploadType" => "resumable",
         "name" => file_name}.to_json)
    rescue Exception
      puts "upload_folder error 3"
    end

    return file_id
  end

  def set_rest_clients
    @drive_manager = RestClient::Resource.new("https://www.googleapis.com/drive/v3/files/",
                                              :headers => {"Authorization" => "Bearer #{@access_token}",
                                                           "Content-Type" => "application/json"})
    @drive_uploader = RestClient::Resource.new("https://www.googleapis.com/upload/drive/v3/files",
                                               :headers => {"Authorization" => "Bearer #{@access_token}"})
  end

  def get_file_ids
    return @file_ids
  end

  def get_folder_ids
    return @folders_ids
  end

  def refresh?
    token_timer = Time.now - @token_tob

    if token_timer > @REFRESH_COOLDOWN
      return true
    else
      return false
    end
  end

  def refresh_token
    @token_tob = Time.now
    @authorizer.set_access_token
    p @access_token = @authorizer.get_access_token
    set_rest_clients
  end
end
