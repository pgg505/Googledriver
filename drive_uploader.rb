require 'json'
require 'rest-client'
require './drive_authorizer.rb'

# Uploads a filesystem to Google Drive and saves file ids
class DriveUploader
  def initialize(filesystem)
    @file_ids = {} # hash of files to ids
    @authorizer = DriveAuthorizer.new
    @access_token = @authorizer.access_token
    @token_lifetime = @authorizer.token_lifetime
    @token_tob = @authorizer.token_tob
    update_drive_manager
    update_drive_uploader
    upload_filesystem(current_dir: filesystem)
    File.open('drive_file_ids.json', 'w')
    File.write('drive_file_ids.json', file_ids.to_json)
  end

  def update_drive_manager # creates REST resource for changing file metadata
    @drive_manager = RestClient::Resource.new(
      'https://www.googleapis.com/drive/v3/files/',
      headers: { 'Authorization' => "Bearer #{@access_token}",
                 'Content-Type' => 'application/json' }
    )
  end

  def update_drive_uploader # creates REST resource for uploading resources
    @drive_uploader = RestClient::Resource.new(
      'https://www.googleapis.com/upload/drive/v3/files',
      headers: { 'Authorization' => "Bearer #{@access_token}" }
    )
  end

  def upload_filesystem(upload_dest: 'root', current_dir: '') # uploads server
    Dir[current_dir + '*'].each do |object| # does not return hidden objects
      if File.directory?(object)
        folder_name = File.basename(object)
        folder_id = upload_folder(folder_name, location: upload_dest)
        upload_filesystem(upload_dest: folder_id,
                          current_dir: "#{current_dir}#{folder_name}/")
      else
        file_name = File.basename(object)
        file_id = upload_file(object, file_name, location: upload_dest)
        @file_ids[object] = file_id
      end
    end
  end

  def upload_folder(folder_name, location: 'root')
    begin
      refresh_token if refresh_due?
      upload = @drive_manager.post(
        { 'name' => folder_name,
          'mimeType' => 'application/vnd.google-apps.folder' }.to_json
      )
    rescue StandardError => error
      warn "#{error}  METHOD  #{__callee__}"
      retry
    end

    folder_id = JSON.parse(upload)['id']

    if location != 'root' # does not change parents if intended location is root
      begin
        refresh_token if refresh_due?
        @drive_manager[folder_id + '?addParents=' + location +
                       '&removeParents=root&alt=json'].patch(
                         { 'uploadType' => 'resumable' }.to_json
                       )
      rescue StandardError => error
        warn "#{error}  METHOD  #{__callee__}"
        retry
      end
    end

    folder_id
  end

  def refresh_token
    @authorizer.refresh_access_token
    @access_token = @authorizer.access_token
    @token_lifetime = @authorizer.token_lifetime
    @token_tob = @authorizer.token_tob
    update_drive_manager
    update_drive_uploader
  end

  def refresh_due?
    token_timer = Time.now - @token_tob
    return false unless token_timer > @token_lifetime * 0.9
    true
  end

  def upload_file(file_path, file_name, location: 'root')
    begin
      payload = File.open(file_path)
    rescue StandardError => error
      warn "#{error}  METHOD  #{__callee__}"
      return
    end

    begin
      refresh_token if refresh_due?
      upload = @drive_uploader.post(
        payload
      )
    rescue StandardError => error
      warn "#{error}  METHOD  #{__callee__}"
      retry
    end

    file_id = JSON.parse(upload)['id']

    begin
      refresh_token if refresh_due?
      @drive_manager[file_id + '?addParents=' + location +
                     '&removeParents=root&alt=json'].patch(
                       { 'uploadType' => 'resumable',
                         'name' => file_name }.to_json
                     )
    rescue StandardError => error
      warn "#{error}  METHOD  #{__callee__}"
      retry
    end

    file_id
  end
end
