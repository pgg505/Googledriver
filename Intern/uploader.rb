#!/usr/bin/env ruby

require "rest-client"
require "json"
require "./authoriser.rb"

class Uploader

  def initialize()
    authoriser = Authoriser.new()
    authoriser.authorise()
    @access_token = authoriser.get_access_token() # @ means it is an instance variable
  end

  def upload_file(file_path, file_name)
    '''(String) -> String. Uploads a given file to Google Drive and returns its generated file ID.'''

    begin
      payload = File.open(file_path)
    rescue => error
      p error
    end

    begin
      response = RestClient.post( # look at adding HTTP headers if problems occur
        "https://www.googleapis.com/upload/drive/v3/files/name='pleaseeee'", # ? is for setting a query on get
        {"uploadType" => "resumable", "upload" => payload},
        {"Authorization" => "Bearer #{@access_token}",
        "Content-Length" => "1000"}
        )
    rescue => error
        p error
    end

    temp_output = response.split("id")[1]
    long_id = temp_output.split("\n")[0] # manipulates string to get file ID
    id = long_id.gsub(/[,:"\ ]/, "")
    return id
  end

  def get_file_metadata(file_id)
    '''(String) -> String. Returns the metadata of a given file.'''

    begin
      metadata = RestClient.get(
        "https://www.googleapis.com/drive/v3/files/" + file_id,
        {"Authorization" => "Bearer #{@access_token}"}
        )
    rescue => error
      p error
    end

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

  def update_file_permission(file_id, email, role)
    payload = {"role" => role, "type" => "group", "emailAddress" => email}.to_json()

    begin
      update = RestClient.post(
        "https://www.googleapis.com/drive/v3/files/" + file_id + "/permissions",
        payload,
        {"Authorization" => "Bearer #{@access_token}",
         "Content-Type" => "application/json"}
        )
    rescue => error
      p error
    end

    return update
  end






  def upload_folder()
    f = File.new("test.txt")
    f = {"name" => "folder", "mimeType" => "application/vnd.google-apps.folder"}.to_json()

    begin
      response = RestClient.post(
        "https://www.googleapis.com/upload/drive/v3/files",
        f,
        {"Authorization" => "Bearer #{@access_token}",
        "Content-Length" => "1000"}
        )
    rescue => error
        p error
    end

    temp_output = response.split("id")[1]
    long_id = temp_output.split("\n")[0] # manipulates string to get file ID
    id = long_id.gsub(/[,:"\ ]/, "")
    return id
  end





  def update_file_folder(file_id, fold_id) # should work but not being given a folder
    payload = {"id" => fold_id}.to_json()

    begin
      update = RestClient.post(
        "https://www.googleapis.com/drive/v3/files/" + file_id + "/parents",
        payload,
        {"Authorization" => "Bearer #{@access_token}",
         "Content-Type" => "application/json"}
        )
    rescue => error
      p error
    end

    return update
  end
end
