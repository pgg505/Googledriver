require 'base64'
require 'json'
require 'rest-client'

# Builds pages for Confluence
class WikiBuilder
  SPACE_KEY = 'CSRV813'.freeze

  def initialize(title, body)
    authorize
    @data_hash = { 'type' => 'page', 'title' => title,
                   'space' => { 'key' => SPACE_KEY }, 'body' => { 'storage' =>
                       { 'value' => body,
                         'representation' => 'storage' } } }.to_json
    @data_hash
  end

  def authorize
    encoded_credentials = Base64.encode64('csrv813:tiongezho2')
    @access_key = 'Basic ' << encoded_credentials
  end

  def get_page_content(page_title)
    begin
      content = RestClient.get(
        'https://wikidev.york.ac.uk/rest/api/content?spaceKey=' << SPACE_KEY <<
        '&title=' << page_title << '&expand=body.view',
        'Authorization' => @access_key
      )
    rescue StandardError => e
      warn e
    end

    content
  end

  def upload_page_content
    begin
      upload = RestClient.post(
        'https://wikidev.york.ac.uk/rest/api/content', @data_hash,
        'Content-Type' => 'application/json', 'Authorization' => @access_key
      )
    rescue StandardError => e
      warn e
    end

    upload
  end
end
