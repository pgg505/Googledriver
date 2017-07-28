require "google/apis/drive_v3"
require "googleauth"
require "googleauth/stores/file_token_store"
require "fileutils"
require "rest-client"
require "json"

class Authorizer
  def initialize
    @OOB_URI = "urn:ietf:wg:oauth:2.0:oob" # standard authorization url
    @CLIENT_SECRETS_PATH = "client_secret.json" # name of client secrets file
    @CREDENTIALS_PATH = File.join(Dir.home, ".credentials", "google_drive_credentials.yaml") # path for credentials file
    @SCOPE = Google::Apis::DriveV3::AUTH_DRIVE_FILE # gives access to files created in program
    authorize
    @token_tob = -1 # token not created yet
    @refresh_token = obtain_refresh_token
    @access_token = generate_access_token
  end

  def authorize
    FileUtils.mkdir_p(File.dirname(@CREDENTIALS_PATH)) # creates the file for credentials data
    @client_id = Google::Auth::ClientId.from_file(@CLIENT_SECRETS_PATH) # reads from client secrets file
    token_store = Google::Auth::Stores::FileTokenStore.new(file: @CREDENTIALS_PATH) # makes token store in credentials file
    authorizer = Google::Auth::UserAuthorizer.new(@client_id, @SCOPE, token_store) # creates new authorizer
    user_id = "default"
    credentials = authorizer.get_credentials(user_id)

    if credentials.nil? # if tokens do not yet exist
      url = authorizer.get_authorization_url(base_url: @OOB_URI)
      puts "Open the following URL and copy and paste the code into the terminal " + url
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(user_id: user_id, code: code, base_url: @OOB_URI) # sets tokens
    end

    return credentials # credentials information
  end

  def generate_access_token
    if defined?(@access_token) == nil # if token not yet set
      temp_string = File.read(@CREDENTIALS_PATH).split('access_token":"')[1] # reads from credentials file
      @access_token = temp_string.split('"')[0]
      @access_token = refresh_access_token
    else # if token already exists
      @access_token = refresh_access_token
    end
  end

  def access_token
    return @access_token
  end

  def obtain_refresh_token
    temp_string = File.read(@CREDENTIALS_PATH).split('refresh_token":"')[1] # reads from credentials file
    @refresh_token = temp_string.split('"')[0]
  end

  def refresh_token
    return @refresh_token
  end

  def refresh_access_token
    client_data = JSON.parse(File.read(@CLIENT_SECRETS_PATH))["installed"]


    payload = {"refresh_token" => refresh_token,
               "client_id" => client_data["client_id"],
               "client_secret" => client_data["client_secret"],
               "grant_type" => "refresh_token"}

    @token_tob = Time.now

    begin
      refresh = RestClient.post(
        "https://www.googleapis.com/oauth2/v4/token",
        payload,
        {"Content-Type" => "application/x-www-form-urlencoded"})
    rescue Exception
      puts "refresh_access_token error"
    end

    return JSON.parse(refresh)["access_token"]
  end

  def token_tob
    return @token_tob
  end
end
