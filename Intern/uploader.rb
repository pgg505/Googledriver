require "rest-client"
require "json"
require "filemagic"
require "./authoriser.rb"

class Uploader # Uploads files and folders to an authorised Google Drive account.
  def initialize()
    authoriser = Authoriser.new()
    authoriser.authorise() # prompts user to authorise their account
    @access_token = authoriser.get_access_token() # saves generated access token
    @drive_uploader = RestClient::Resource.new("https://www.googleapis.com/drive/v3/files/", # used for all requests except file upload
                                               :headers => {"Authorization" => "Bearer #{@access_token}"})
  end

  def upload_folder(folder_name, hex_colour: "#FFFF00", location: "root")
    begin
      upload = @drive_uploader.post(
        {"name" => folder_name,
         "mimeType" => "application/vnd.google-apps.folder",
         "folderColorRgb" => hex_colour}.to_json(),
        {"Content-Type" => "application/json"})
    rescue => error
        p error
    end

    parsed_output = JSON.parse(upload)
    id = parsed_output["id"]

    if location != "root" then # does not need to change parents if intended location is root
      begin
        move = @drive_uploader[id + "?addParents=" + location + "&removeParents=root&alt=json"].patch(
          {"uploadType" => "resumable"}.to_json(),
          {"Content-Type" => "application/json"})
      rescue => error
        p error
      end
    end

    return id
  end

  def update_file_permission(file_id, email)
    payload = {"role" => "writer",
               "type" => "group",
               "emailAddress" => email}.to_json()

    begin
      update = @drive_uploader[file_id + "/permissions"].post(
        payload,
        {"Content-Type" => "application/json"})
    rescue => error
      p error
    end

    return update
  end

  def upload_file(file_path, file_name, folder_id: "root")
    '''(String, String, String) -> String. Uploads a given file to the specified folder and returns its generated file ID.'''

    begin
      file_type = FileMagic.new(FileMagic::MAGIC_MIME).file(file_path).split(";")[0]
      payload = File.open(file_path)
    rescue => error
      p error
    end

    if file_type == "text/plain" then # uploads as JSON which is problematic
      begin
        upload = RestClient.post( # uploads file
          "https://www.googleapis.com/upload/drive/v3/files",
          payload,
          {"Authorization" => "Bearer #{@access_token}", "Content-Type" => "application/json"})
      rescue => error
          p error
      end
    else
      begin
        upload = RestClient.post( # uploads file
          "https://www.googleapis.com/upload/drive/v3/files",
          payload,
          {"Authorization" => "Bearer #{@access_token}"})
      rescue => error
          p error
      end
    end

    parsed_output = JSON.parse(upload)
    id = parsed_output["id"]

    begin
      rename = @drive_uploader[id + "?addParents=" + folder_id + "&removeParents=root&alt=json"].patch( # changes file name and puts in folder
        {"uploadType" => "resumable", "name" => file_name}.to_json(),
        {"Content-Type" => "application/json"})
    rescue => error
      p error
    end
    return id
  end
end
