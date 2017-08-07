require 'json'
require 'oauth2'
require 'rest-client'

# Authorizes a Google Drive account and generates access tokens
class DriveAuthorizer
  SCOPE = 'https://www.googleapis.com/auth/drive.file'.freeze
  REDIRECT_URI = 'urn:ietf:wg:oauth:2.0:oob'.freeze # standard authorization uri
  CLIENT_SECRETS_PATH = 'client_secret.json'.freeze # name of secrets file
  attr_reader :access_token

  def initialize
    create_client_data
    create_authorization_url
    refresh_access_token
  end

  def create_client_data
    client_data = JSON.parse(File.read(CLIENT_SECRETS_PATH))['installed']
    @client_id = client_data['client_id']
    @client_secret = client_data['client_secret']
  end

  def create_authorization_url
    client = OAuth2::Client.new(@client_id, @client_secret,
                                authorize_url: '/o/oauth2/auth',
                                token_url: '/o/oauth2/token',
                                site: 'https://accounts.google.com')
    url = client.auth_code.authorize_url(redirect_uri: REDIRECT_URI,
                                         scope: SCOPE, access_type: 'offline')
    puts 'Open the following link ' + url
    code = gets
    token = client.auth_code.get_token(code, redirect_uri: REDIRECT_URI)
    @refresh_token = token.refresh_token
  end

  def create_refresh_payload
    payload = { 'refresh_token' => @refresh_token, 'client_id' => @client_id,
                'client_secret' => @client_secret,
                'grant_type' => 'refresh_token' }
    payload
  end

  def refresh_access_token
    payload = create_refresh_payload

    begin
      refresh = RestClient.post(
        'https://www.googleapis.com/oauth2/v4/token',
        payload, 'Content-Type' => 'application/x-www-form-urlencoded'
      )
    rescue StandardError => e
      warn e
      exit 1
    end

    @access_token = JSON.parse(refresh)['access_token']
  end

  private :create_client_data, :create_authorization_url,
          :create_refresh_payload, :refresh_access_token
end
