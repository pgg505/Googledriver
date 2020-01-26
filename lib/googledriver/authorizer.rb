module Googledriver

  # Authorizes a user to Google Drive and generates access tokens.
  class Authorizer
    # Authorization scope which only allows program to manipulate files it
    # created.
    SCOPE = 'https://www.googleapis.com/auth/drive.file'.freeze

    # Standard redirect uri for authorization.
    REDIRECT_URI = 'urn:ietf:wg:oauth:2.0:oob'.freeze # standard redirect uri

    # The access token created during authorization which is needed to perform
    # uploads to Google Drive.
    attr_reader :access_token

    # The lifetime of an access token in seconds which dictates how often a
    # token needs to be refreshed.
    attr_reader :token_lifetime

    # The time of birth of the current access token.
    attr_reader :token_tob

    # Constructs a new Authorizer by reading client data from a file and
    # creating a REST resource.
    def initialize(client_secrets_path)
      @client_secrets_path = client_secrets_path
      update_client_data
      create_refresh_resource
    end

    # Generates an authorization url for the user in order to obtain an initial
    # refresh token.
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

    # Refreshes the access token and updates resources appropriately.
    def refresh_access_token
      @token_tob = Time.now

      begin
        refresh = @refresh_manager.post(
          build_refresh_payload
        )
      rescue StandardError => e
        warn "#{e};  METHOD  #{__callee__};  RESOURCE  #{@refresh_manager}"
        retry
      end

      update_refresh_data(refresh)
    end

    private

    def update_client_data
      begin
        file_content = File.read(@client_secrets_path)
      rescue Errno::ENOENT
        puts 'Cannot locate file.'
        exit 66
      end

      client_data = JSON.parse(file_content)['installed']
      @client_id = client_data['client_id']
      @client_secret = client_data['client_secret']
    end

    def create_refresh_resource
      @refresh_manager = RestClient::Resource.new(
        'https://www.googleapis.com/oauth2/v4/token',
        headers: { 'Content-Type' => 'application/x-www-form-urlencoded' }
      )
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
  end
end
