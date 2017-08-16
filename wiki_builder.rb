require 'json'
require 'base64'
require 'rest-client'
require './web_scraper.rb'

# Builds a Confluence wiki
class WikiBuilder
  def initialize(space_name, space_key)
    @page_ids = {} # hash of pages to ids
    @page_links = {} # hash of pages to tiny links
    @space_name = space_name
    @space_key = space_key
    @scraper = WebScraper.new
    @page_contents = @scraper.page_contents
    @page_titles = @scraper.page_titles
    create_access_key
    create_manager_resource
    create_uploader_resource
    upload_space
    upload_blanks
    upload_website
  end

  def create_access_key
    username = @scraper.username
    password = @scraper.password
    encoded_credentials = Base64.encode64("#{username}:#{password}")
    @access_key = "Basic #{encoded_credentials}"
  end

  def create_manager_resource
    @space_uploader = RestClient::Resource.new(
      'https://wiki.york.ac.uk/rest/api/space/_private',
      headers: { 'Authorization' => @access_key,
                 'Content-Type' => 'application/json' }
    )
  end

  def create_uploader_resource
    @page_uploader = RestClient::Resource.new(
      'https://wiki.york.ac.uk/rest/api/content',
      headers: { 'Authorization' => @access_key,
                 'Content-Type' => 'application/json' }
    )
  end

  def upload_space
    payload = { 'name' => @space_name, 'key' => @space_key, 'metadata' => nil }

    begin
      @space_uploader.post(
        payload.to_json
      )
    rescue StandardError => error
      warn "#{error};  METHOD  #{__callee__};  RESOURCE  #{payload}"
      retry
    end
  end

  def upload_blanks
    @page_contents.each do |page|
      payload = { 'type' => 'page', 'title' => page[0],
                  'space' => { 'key' => @space_key },
                  'body' => { 'storage' => { 'value' => '',
                                             'representation' => 'storage' } } }
      upload_data = JSON.parse(upload_empty(payload))
      @page_ids[page[0]] = upload_data['id']
      links_data = upload_data['_links']
      tiny_link = links_data['base'] + links_data['tinyui']
      @page_links[page[0]] = tiny_link
    end
  end

  def upload_empty(payload)
    begin
      upload = @page_uploader.post(
        payload.to_json
      )
    rescue StandardError => error
      warn "#{error};  METHOD  #{__callee__};  RESOURCE  #{payload}"
      retry
    end

    upload
  end

  def upload_website
    @page_contents.each do |page| # gsub content for tiny links
      body_value = page[1]

      @page_links.each do |link|
        body_value = body_value.gsub("f=\"#{link[0]}\"", "f=\"#{link[1]}\"")
      end

      payload = { 'version' => { 'number' => 2 }, 'type' => 'page',
                  'title' => @page_titles[page[0]],
                  'body' => { 'storage' => { 'value' => body_value,
                                             'representation' => 'storage' } } }
      upload_page(payload, @page_ids[page[0]])
    end
  end

  def upload_page(payload, page_id)
    begin
      upload = @page_uploader["/#{page_id}"].put(
        payload.to_json
      )
    rescue StandardError => error
      warn "#{error};  METHOD  #{__callee__};  RESOURCE  #{payload}"
      retry
    end

    upload
  end
end
