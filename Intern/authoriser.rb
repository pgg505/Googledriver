require "google/apis/drive_v3"
require "googleauth"
require "googleauth/stores/file_token_store"
require "fileutils"

class Authoriser

  def initialize()
    @OOB_URI = "urn:ietf:wg:oauth:2.0:oob"
    @APPLICATION_NAME = "Google Drive"
    @CLIENT_SECRETS_PATH = "client_secret.json"
    @CREDENTIALS_PATH = File.join(Dir.home, ".credentials", "drive-ruby-quickstart.yaml")
    @SCOPE = Google::Apis::DriveV3::AUTH_DRIVE_FILE # gives access to files created in program
  end

  # @return [Google::Auth::UserRefreshCredentials] OAuth2 credentials
  def authorise()
    '''() -> String. Prompts user to authenticate account and returns credentials.'''

    FileUtils.mkdir_p(File.dirname(@CREDENTIALS_PATH))
    client_id = Google::Auth::ClientId.from_file(@CLIENT_SECRETS_PATH)
    token_store = Google::Auth::Stores::FileTokenStore.new(file: @CREDENTIALS_PATH)
    authorizer = Google::Auth::UserAuthorizer.new(
      client_id, @SCOPE, token_store)
    user_id = "default"
    credentials = authorizer.get_credentials(user_id)

    if credentials.nil?
      url = authorizer.get_authorization_url(
        base_url: @OOB_URI)
      puts "Open the following URL in the browser and enter the " +
           "resulting code after authorization"
      puts url
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(
        user_id: user_id, code: code, base_url: @OOB_URI)
    end

    credentials
  end

  def get_access_token()
    '''() -> String. Returns the access token generated during the authentication process.'''

    temp_string = File.read(@CREDENTIALS_PATH).split('access_token":"')[1]
    token = temp_string.split('"')[0]
    return token
  end
end
