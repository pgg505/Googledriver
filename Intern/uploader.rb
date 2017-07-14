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

  def upload_file(file_path)
    '''(String) -> String. Uploads a given file to Google Drive and returns its generated file ID.'''

    payload = File.open(file_path)
    response = RestClient.post( # look at adding HTTP headers if problems occur
      "https://www.googleapis.com/upload/drive/v3/files",
      {"uploadType" => "resumable", "upload" => payload},
      {"Authorization" => "Bearer #{@access_token}",
      "Content-Length" => "1000"}
      )
    temp_output = response.split("id")[1]
    long_id = temp_output.split("\n")[0] # manipulates string to get file ID
    id = long_id.gsub(/[,:"\ ]/, "")
    return id
  end

  def get_file_metadata(file_id)
    '''(String) -> String. Returns the metadata of a given file.'''

    metadata = RestClient.get(
      "https://www.googleapis.com/drive/v3/files/" + file_id,
      {"Authorization" => "Bearer #{@access_token}"}
      )
    return metadata
  end

  def get_file_permissionid(file_id)
    '''(String) -> String. Returns the permission ID of a given file.'''

      clean_metadata = get_file_metadata(file_id).split("permissionId")[1].split("\n")[0]
      permission_id = clean_metadata.gsub(/[,:"\ ]/, "")
      return permission_id
  end

  def get_file_permission(file_id, permission_id)
    permission = RestClient.get(
      "https://www.googleapis.com/drive/v3/files/" + file_id + "/permissions/" + permission_id,
      {"Authorization" => "Bearer #{@access_token}"}
      )
    return permission
  end

  def update_file_metadata(file_id, element, new_data)
    '''(String, String, String) -> String. For a given file and data element, updates that piece of metadata.'''

      payload = {"uploadType" => "resumable", element => new_data}.to_json()
      update = RestClient.patch(
        "https://www.googleapis.com/drive/v3/files/" + file_id,
        payload,
        {"Authorization" => "Bearer #{@access_token}",
         "Content-Type" => "application/json"}
        )
    return update
  end

  def update_file_permission(file_id, email)
    payload = {"role" => "writer", "type" => "group", "emailAddress" => email}.to_json()

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

end
