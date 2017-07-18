
    def get_file_metadata(file_id)
      '''(String) -> String. Returns the metadata of a given file.'''

      begin
        metadata = RestClient.get(
          "https://www.googleapis.com/drive/v3/files/" + file_id,
          {"Authorization" => "Bearer #{@access_token}"})
      rescue => error
        p error
      end

      metadata = JSON.parse(metadata)
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
