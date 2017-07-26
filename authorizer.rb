require "google/apis/drive_v3"
require "googleauth"
require "googleauth/stores/file_token_store"
require "fileutils"
require "rest-client"
require "json"

class Authorizer
  def initialize
    @OOB_URI = "urn:ietf:wg:oauth:2.0:oob"
    @CLIENT_SECRETS_PATH = "client_secret.json"
    @CREDENTIALS_PATH = File.join(Dir.home, ".credentials", "google-drive-credentials.yaml")
    @SCOPE = Google::Apis::DriveV3::AUTH_DRIVE_FILE # gives access to files created in program
    @access_token = ""
  end

  def authorize
    FileUtils.mkdir_p(File.dirname(@CREDENTIALS_PATH)) # creates a file for credentials data
    @client_id = Google::Auth::ClientId.from_file(@CLIENT_SECRETS_PATH)
    token_store = Google::Auth::Stores::FileTokenStore.new(file: @CREDENTIALS_PATH)
    authorizer = Google::Auth::UserAuthorizer.new(@client_id, @SCOPE, token_store)
    user_id = "default"
    credentials = authorizer.get_credentials(user_id)

    if credentials.nil?
      url = authorizer.get_authorization_url(base_url: @OOB_URI)
      puts "Open the following URL and copy and paste the code into the terminal " + url
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(user_id: user_id, code: code, base_url: @OOB_URI)
    end

    return credentials
  end

  def set_access_token
    if @access_token == "" # if token not yet set
      temp_string = File.read(@CREDENTIALS_PATH).split('access_token":"')[1] # read from credentials file
      @access_token = temp_string.split('"')[0]
      @access_token = refresh_access_token
    else # if token already exists
      @access_token = refresh_access_token
    end
  end

  def get_access_token
    return @access_token
  end

  def get_refresh_token
    temp_string = File.read(@CREDENTIALS_PATH).split('refresh_token":"')[1]
    refresh_token = temp_string.split('"')[0]
    return refresh_token
  end

  def refresh_access_token
    client_data = JSON.parse(File.read(@CLIENT_SECRETS_PATH))["installed"]

    begin
      payload = {"refresh_token" => get_refresh_token,
                 "client_id" => client_data["client_id"],
                 "client_secret" => client_data["client_secret"],
                 "grant_type" => "refresh_token"}

      refresh = RestClient.post(
        "https://www.googleapis.com/oauth2/v4/token",
        payload,
        {"Content-Type" => "application/x-www-form-urlencoded"})
    rescue Exception
      puts "refresh_access_token error"
    end

    return JSON.parse(refresh)["access_token"]
  end
end
