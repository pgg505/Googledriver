require 'json'
require 'oauth2'
require 'rest-client'

# Authorizes a Google Drive account
class Authorizer
  def initialize
    @REDIRECT_URI = 'urn:ietf:wg:oauth:2.0:oob' # standard authorization url
    @SCOPE = 'https://www.googleapis.com/auth/drive.file' # change to fit use
    @CLIENT_SECRETS_PATH = 'client_secret.json' # name of client secrets file
    @token_tob = -1 # token not created yet
    @refresh_token = ''
    authorize
    @access_token = refresh_access_token
  end

  def authorize
    @client_data = JSON.parse(File.read(@CLIENT_SECRETS_PATH))['installed']
    @client_id = @client_data['client_id']
    @client_secret = @client_data['client_secret']
    client = OAuth2::Client.new(@client_id,
                                @client_secret,
                                authorize_url: '/o/oauth2/auth',
                                token_url: '/o/oauth2/token',
                                site: 'https://accounts.google.com')
    url = client.auth_code.authorize_url(redirect_uri: @OOB_URI, scope: @SCOPE)
    puts 'Open the following link ' + url
    code = gets
    token = client.auth_code.get_token(code, redirect_uri: @OOB_URI)
    @refresh_token = token.refresh_token
  end

  def refresh_access_token
    payload = {"refresh_token" => @refresh_token,
               "client_id" => @client_id,
               "client_secret" => @client_secret,
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

  def access_token
    return @access_token
  end

  def refresh_token
    return @refresh_token
  end

  def token_tob
    return @token_tob
  end
end
