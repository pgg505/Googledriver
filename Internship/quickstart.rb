require 'google/apis/drive_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'

OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'
APPLICATION_NAME = 'Drive API Ruby Quickstart'
CLIENT_SECRETS_PATH = 'client_secret.json'
CREDENTIALS_PATH = File.join(Dir.home, '.credentials', # Saves credentials here
                             "drive-ruby-quickstart.yaml")
SCOPE = Google::Apis::DriveV3::AUTH_DRIVE_FILE # Gives access to files created in program

# @return [Google::Auth::UserRefreshCredentials] OAuth2 credentials
def authorize
  FileUtils.mkdir_p(File.dirname(CREDENTIALS_PATH))

  client_id = Google::Auth::ClientId.from_file(CLIENT_SECRETS_PATH)
  token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
  authorizer = Google::Auth::UserAuthorizer.new(
    client_id, SCOPE, token_store)
  user_id = 'default'
  credentials = authorizer.get_credentials(user_id)
  if credentials.nil?
    url = authorizer.get_authorization_url(
      base_url: OOB_URI)
    puts "Open the following URL in the browser and enter the " +
         "resulting code after authorization"
    puts url
    code = gets
    credentials = authorizer.get_and_store_credentials_from_code(
      user_id: user_id, code: code, base_url: OOB_URI)
  end
  credentials
end

# Initialize the API
service = Google::Apis::DriveV3::DriveService.new
service.client_options.application_name = APPLICATION_NAME
service.authorization = authorize

# Upload a file
file_metadata = {name: 'Test'}
file = service.create_file(file_metadata, fields: 'id',
                           upload_source: 'flower.jpeg',
                           content_type: 'image/jpeg')

file = service.update_file(file.id, file_metadata,
                           fields: 'id, name, permissions',
                           upload_source: 'flower.jpeg',
                           content_type: 'image/jpeg')

puts "Uploaded #{file.name} (id:#{file.id}) #{file.permissions}"

# Returns last file accessed in session
response = service.list_files(page_size: 1,
                              fields: 'nextPageToken, files(id, name, permissions)')
response.files.each do |file|
  puts "Accessed #{file.name} (id:#{file.id}) #{file.permissions}"
end
