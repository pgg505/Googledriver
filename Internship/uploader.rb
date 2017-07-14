#!/usr/bin/env ruby

require "rest-client"
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
      "https://www.googleapis.com/drive/v2/files/" + file_id,
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

  def update_file_metadata(file_id)
    update = RestClient.patch(
      "https://www.googleapis.com/drive/v3/files/" + file_id,
      {"uploadType" => "resumable"},
      {"Authorization" => "Bearer #{@access_token}"}
      )
    return update
  end

end
