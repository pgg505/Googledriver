require "rest-client"
require "json"
require "./authoriser.rb"

class Uploader
  '''Uploads files and folders to Google Drive.'''

  def initialize()
    authoriser = Authoriser.new()
    authoriser.authorise()
    @access_token = authoriser.get_access_token() # @ means it is an instance variable
  end

  def upload_folder(folder_name, hex_colour: "#FFFF00", location: "root")
    '''(String, ?String, ?String) -> String. Uploads a folder to a specified location.'''

    begin
      upload = RestClient.post(
        "https://www.googleapis.com/drive/v3/files",
        {"name" => folder_name,
         "mimeType" => "application/vnd.google-apps.folder",
         "folderColorRgb" => hex_colour}.to_json(),
        {"Authorization" => "Bearer #{@access_token}",
         "Content-Type" => "application/json"})
    rescue => error
        p error
    end

    parsed_output = JSON.parse(upload)
    id = parsed_output["id"]

    if location != "root" then
      begin
        move = RestClient.patch(
          "https://www.googleapis.com/drive/v3/files/" + id + "?addParents=" + location + "&removeParents=root&alt=json",
          {"uploadType" => "resumable"}.to_json(),
          {"Authorization" => "Bearer #{@access_token}",
           "Content-Type" => "application/json"})
      rescue => error
        p error
      end
    end

    return id
  end

  def update_file_permission(file_id, email)
    '''(String, String) -> String. Changes the permission of a given file to the specified email address.'''

    payload = {"role" => "writer", "type" => "group", "emailAddress" => email}.to_json()

    begin
      update = RestClient.post(
        "https://www.googleapis.com/drive/v3/files/" + file_id + "/permissions",
        payload,
        {"Authorization" => "Bearer #{@access_token}",
         "Content-Type" => "application/json"})
    rescue => error
      p error
    end

    return update
  end

  def upload_file(file_path, file_name, folder_id)
    '''(String, String, String) -> String. Uploads a given file to the specified folder and returns its generated file ID.'''

    begin
      payload = File.open(file_path)
    rescue => error
      p error
    end

    begin
      upload = RestClient.post( # uploads file
        "https://www.googleapis.com/upload/drive/v3/files",
        {"uploadType" => "resumable", "upload" => payload},
        {"Authorization" => "Bearer #{@access_token}"})
    rescue => error
        p error
    end

    parsed_output = JSON.parse(upload)
    id = parsed_output["id"]

    begin
      rename = RestClient.patch( # changes file name and puts in folder
        "https://www.googleapis.com/drive/v3/files/" + id + "?addParents=" + folder_id + "&removeParents=root&alt=json",
        {"uploadType" => "resumable", "name" => file_name}.to_json(),
        {"Authorization" => "Bearer #{@access_token}",
         "Content-Type" => "application/json"})
    rescue => error
      p error
    end
    return id
  end
end
