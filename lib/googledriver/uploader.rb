module Googledriver

  # Uploads a filesystem to Google Drive and saves file ids.
  class Uploader
    # Constructs a new Uploader by building an empty hash for file ids and
    # making an Authorizer object to handle the creation of REST resources.
    def initialize(client_secrets_path)
      @file_ids = {}
      @authorizer = Googledriver::Authorizer.new(client_secrets_path)
      @authorizer.create_refresh_token
      @authorizer.refresh_access_token
      @access_token = @authorizer.access_token
      @token_tob = @authorizer.token_tob
      @token_lifetime = @authorizer.token_lifetime
      create_manager_resource
      create_uploader_resource
    end

    # Recursively uploads a local filesystem specified by a file path to a given
    # folder in Google Drive.
    def upload_filesystem(directory: '', upload_dest: 'root')
      directory = "#{directory}/" unless directory[-1] == '/'

      Dir[directory + '*'].each do |object|
        if File.directory?(object)
          folder_name = File.basename(object)
          folder_id = upload_folder(folder_name, location: upload_dest)
          upload_filesystem(upload_dest: folder_id,
                            directory: "#{directory}#{folder_name}/")
        else
          file_name = File.basename(object)
          file_id = upload_file(object, file_name, location: upload_dest)
          @file_ids[object] = file_id
        end
      end
    end

    # Uploads a local folder specified by a file path to a given folder in
    # Google Drive.
    def upload_folder(folder_name, location: 'root')
      begin
        update_refresh_token if refresh_due?
        upload = @drive_manager.post(
          { 'name' => folder_name,
            'mimeType' => 'application/vnd.google-apps.folder' }.to_json
        )
      rescue StandardError => error
        warn "#{error};  METHOD  #{__callee__};  RESOURCE  #{folder_name}"
        retry
      end

      folder_id = JSON.parse(upload)['id']

      if location != 'root'
        begin
          update_refresh_token if refresh_due?
          @drive_manager[folder_id + '?addParents=' + location +
                         '&removeParents=root&alt=json'].patch(
                           { 'uploadType' => 'resumable' }.to_json
                         )
        rescue StandardError => error
          warn "#{error};  METHOD  #{__callee__};  RESOURCE  #{folder_name}"
          retry
        end
      end

      folder_id
    end

    # Uploads a local file specified by a file path to a given folder in
    # Google Drive.
    def upload_file(file_path, file_name, location: 'root')
      begin
        payload = File.open(file_path)
      rescue StandardError => error
        warn "#{error};  METHOD  #{__callee__};  RESOURCE  #{file_path}"
        return
      end

      begin
        update_refresh_token if refresh_due?
        upload = @drive_uploader.post(
          payload
        )
      rescue StandardError => error
        warn "#{error};  METHOD  #{__callee__};  RESOURCE  #{file_path}"
        retry
      end

      file_id = JSON.parse(upload)['id']
      @file_ids[file_path] = file_id

      begin
        update_refresh_token if refresh_due?
        @drive_manager[file_id + '?addParents=' + location +
                       '&removeParents=root&alt=json'].patch(
                         { 'uploadType' => 'resumable',
                           'name' => file_name }.to_json
                       )
      rescue StandardError => error
        warn "#{error};  METHOD  #{__callee__};  RESOURCE  #{file_path}"
        retry
      end

      payload.close
      file_id
    end

    # Saves the file ids hash to a json file in the working directory.
    def archive_file_ids
      archive = File.open('drive_file_ids.json', 'w')
      File.write('drive_file_ids.json', @file_ids.to_json)
      archive.close
    end

    # Returns the metadata of a given file.
    def obtain_file_metadata(file_id)
      begin
        metadata = @drive_manager[file_id].get
      rescue StandardError => error
        warn "#{error};  METHOD  #{__callee__};  RESOURCE  #{file_path}"
        return
      end

      metadata = JSON.parse(metadata)
      metadata
    end

    # Updates a piece of metadata for a given file.
    def update_file_metadata(file_id, element, new_data)
      payload = { 'uploadType' => 'resumable', element => new_data }.to_json

      begin
        update = @drive_manager[file_id].patch(
          payload
        )
      rescue StandardError => error
        warn "#{error};  METHOD  #{__callee__};  RESOURCE  #{file_path}"
        return
      end

      update
    end

    # Shares a given file with an individual or group email address.
    def update_file_permission(file_id, email)
      payload = { 'role' => 'writer', 'type' => 'group',
                  'emailAddress' => email }.to_json

      begin
        update = @drive_manager[file_id + '/permissions'].post(
          payload
        )
      rescue StandardError => error
        warn "#{error};  METHOD  #{__callee__};  RESOURCE  #{file_path}"
        return
      end

      update
    end

    private

    def create_manager_resource
      @drive_manager = RestClient::Resource.new(
        'https://www.googleapis.com/drive/v3/files/',
        headers: { 'Authorization' => "Bearer #{@access_token}",
                   'Content-Type' => 'application/json' }
      )
    end

    def create_uploader_resource
      @drive_uploader = RestClient::Resource.new(
        'https://www.googleapis.com/upload/drive/v3/files',
        headers: { 'Authorization' => "Bearer #{@access_token}" }
      )
    end

    def update_refresh_token
      @authorizer.refresh_access_token
      @access_token = @authorizer.access_token
      @token_lifetime = @authorizer.token_lifetime
      @token_tob = @authorizer.token_tob
      create_manager_resource
      create_uploader_resource
    end

    def refresh_due?
      token_timer = Time.now - @token_tob
      return false unless token_timer > @token_lifetime * 0.9
      true
    end
  end
end
