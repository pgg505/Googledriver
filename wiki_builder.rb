require 'json'
require 'base64'
require 'rest-client'

# Builds a Confluence wiki
class WikiBuilder
  SPACE_KEY = 'CSRV813'.freeze

  def initialize(content)
    authorize
    create_wiki_space

    content.each do |page|
      begin
        @data_hash = { 'type' => 'page', 'title' => page[0],
                       'space' => { 'key' => SPACE_KEY }, 'body' => { 'storage' =>
                           { 'value' => page[1],
                             'representation' => 'storage' } } }.to_json
        upload_page_content
      rescue StandardError => e
        puts page
        warn e
      end
    end
  end

  def authorize
    encoded_credentials = Base64.encode64('csrv813:tiongezho2')
    @access_key = "Basic #{encoded_credentials}"
  end

  def create_wiki_space
    space_hash = { 'key' => SPACE_KEY, 'name' => 'My Test Space',
                   'description' => { 'value' => 'asdf',
                                      'representation' => 'plain' },
                   'metadata' => {} }.to_json

    begin
      upload = RestClient.post(
        'https://wiki.york.ac.uk/rest/api/space', space_hash,
        'Content-Type' => 'application/json', 'Authorization' => @access_key
      )
    rescue StandardError => error
      warn "#{error}  METHOD  #{__callee__}"
    end

    upload
  end

  def upload_page_content
    begin
      upload = RestClient.post(
        'https://wiki.york.ac.uk/rest/api/content', @data_hash,
        'Content-Type' => 'application/json', 'Authorization' => @access_key
      )
    rescue StandardError => e
      warn e.to_s << '   PAGE   ' << JSON.parse(@data_hash)['title'].to_s
    end

    upload
  end
end
