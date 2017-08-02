require './authorizer.rb'
require 'rest-client'
require 'json'

# Uploads a filesystem to Google Drive
class Uploader
  TOKEN_LIFETIME = 3600 # time in seconds before access token is made void
  attr_reader :file_ids, :folder_ids, :failed_uploads

  def initialize
    @file_ids = {} # hash of files to ids
    @folder_ids = {} # hash of folders to ids
    @failed_uploads = []
    @authorizer = Authorizer.new
    @access_token = @authorizer.access_token
    update_drive_manager
    update_drive_uploader
  end

  def update_drive_manager
    @drive_manager = RestClient::Resource.new(
      'https://www.googleapis.com/drive/v3/files/',
      headers: { 'Authorization' => 'Bearer ' + @access_token,
                 'Content-Type' => 'application/json' }
    )
  end

  def update_drive_uploader
    @drive_uploader = RestClient::Resource.new(
      'https://www.googleapis.com/upload/drive/v3/files',
      headers: { 'Authorization' => 'Bearer ' + @access_token }
    )
  end

  def upload_filesystem(upload_dest: 'root', current_dir: '')
    Dir[current_dir + '*'].each do |object| # does not return hidden objects
      if object.include?('.') # checks if object is a file
        file_name = object.split('/')[-1]
        file_id = upload_file(object, file_name, location: upload_dest)
        @file_ids[object] = file_id
      else
        folder_name = object.split('/')[-1]
        folder_id = upload_folder(folder_name, location: upload_dest)
        @folder_ids[object] = folder_id
        upload_filesystem(upload_dest: folder_id,
                          current_dir: current_dir + folder_name + '/')
      end
    end
  end

  def upload_folder(folder_name, location: 'root', hex_colour: '#929292')
    refresh_token if refresh?

    begin
      upload = @drive_manager.post(
        { 'name' => folder_name,
          'mimeType' => 'application/vnd.google-apps.folder',
          'folderColorRgb' => hex_colour }.to_json
      )
    rescue StandardError => e
      puts e
    end

    folder_id = JSON.parse(upload)['id']

    if location != 'root' # does not change parents if intended location is root
      refresh_token if refresh?

      begin
        @drive_manager[folder_id + '?addParents=' + location +
                       '&removeParents=root&alt=json'].patch(
                         { 'uploadType' => 'resumable' }.to_json
                       )
      rescue StandardError => e
        puts e
      end
    end

    folder_id
  end

  def upload_file(file_path, file_name, location: 'root')
    refresh_token if refresh?

    begin
      payload = File.open(file_path)
    rescue StandardError => e
      puts e
      @failed_uploads.push(file_path)
      return
    end

    refresh_token if refresh?

    begin
      upload = @drive_uploader.post(
        payload
      )
    rescue StandardError => e
      puts e
      @failed_uploads.push(file_path)
      return
    end

    file_id = JSON.parse(upload)['id']

    refresh_token if refresh?

    begin
      @drive_manager[file_id + '?addParents=' + location +
                     '&removeParents=root&alt=json'].patch(
                       { 'uploadType' => 'resumable',
                         'name' => file_name }.to_json
                     )
    rescue StandardError => e
      puts e
      @failed_uploads.push(file_path)
      return
    end

    file_id
  end

  def refresh_token
    @authorizer.refresh_access_token
    @access_token = @authorizer.access_token
    update_drive_manager
    update_drive_uploader
  end

  def refresh?
    token_timer = Time.now - @authorizer.token_tob
    return false unless token_timer > (TOKEN_LIFETIME - 600)
    true
  end
end
