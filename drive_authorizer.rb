require 'json'
require 'oauth2'
require 'rest-client'

# Authorizes a user to Google Drive and generates access tokens
class DriveAuthorizer
  SCOPE = 'https://www.googleapis.com/auth/drive.file'.freeze
  REDIRECT_URI = 'urn:ietf:wg:oauth:2.0:oob'.freeze # standard redirect uri
  CLIENT_SECRETS_PATH = 'client_secret.json'.freeze # name of secrets file
  attr_reader :access_token, :token_lifetime, :token_tob

  def initialize
    update_client_data
    create_refresh_token
    create_refresh_resource
    refresh_access_token
  end

  def update_client_data
    file_content = File.read(CLIENT_SECRETS_PATH)
    client_data = JSON.parse(file_content)['installed']
    @client_id = client_data['client_id']
    @client_secret = client_data['client_secret']
  end

  def create_refresh_token
    client = OAuth2::Client.new(@client_id, @client_secret,
                                authorize_url: '/o/oauth2/auth',
                                token_url: '/o/oauth2/token',
                                site: 'https://accounts.google.com')
    url = client.auth_code.authorize_url(redirect_uri: REDIRECT_URI,
                                         scope: SCOPE, access_type: 'offline')
    puts "Open the following link and follow the onscreen instructions #{url}"
    code = gets
    token = client.auth_code.get_token(code, redirect_uri: REDIRECT_URI)
    @refresh_token = token.refresh_token
  end

  def create_refresh_resource
    @refresh_manager = RestClient::Resource.new(
      'https://www.googleapis.com/oauth2/v4/token',
      headers: { 'Content-Type' => 'application/x-www-form-urlencoded' }
    )
  end

  def refresh_access_token
    @token_tob = Time.now

    begin
      refresh = @refresh_manager.post(
        build_refresh_payload
      )
    rescue StandardError => error
      warn "#{error};  METHOD  #{__callee__};  RESOURCE  #{@refresh_manager}"
      retry
    end

    update_refresh_data(refresh)
  end

  def build_refresh_payload
    payload = { 'refresh_token' => @refresh_token, 'client_id' => @client_id,
                'client_secret' => @client_secret,
                'grant_type' => 'refresh_token' }
    payload
  end

  def update_refresh_data(refresh_data)
    processed_data = JSON.parse(refresh_data)
    @token_lifetime = processed_data['expires_in']
    @access_token = processed_data['access_token']
  end

  private :update_client_data, :create_refresh_token, :create_refresh_resource,
          :build_refresh_payload, :update_refresh_data
end
