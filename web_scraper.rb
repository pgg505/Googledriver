require 'uri'
require 'json'
require 'open-uri'
require 'nokogiri'

# Scrapes a Drupal website
class WebScraper
  NEW_LINE = '<p></p>'.freeze # used to emulate line breaks
  DRIVE_BASE_LINK = 'https://drive.google.com/open?id='.freeze
  FILE_IDS_PATH = 'drive_file_ids.json'.freeze
  CLIENT_CREDENTIALS_PATH = 'client_credentials.json'.freeze
  attr_reader :page_contents, :page_titles, :password, :username

  def initialize
    @internal_links = []
    @page_contents = {} # hash of pages to markup code
    @page_titles = {} # hash of pages to more informative titles
    update_client_data
    create_file_ids
    create_page_doc
    scrape_website
  end

  def update_client_data
    file_content = File.read(CLIENT_CREDENTIALS_PATH)
    client_data = JSON.parse(file_content)
    @username = client_data['username']
    @password = client_data['password']
    @base_uri = client_data['base_uri']
  end

  def create_file_ids
    file_content = File.read(FILE_IDS_PATH)
    @drive_file_ids = JSON.parse(file_content)
  end

  def create_page_doc(page: '')
    new_page = open(@base_uri + page,
                    http_basic_authentication: [@username, @password])
    @doc = Nokogiri::HTML(new_page)
  end

  def scrape_website
    push_internal_links # gets internal links from homepage
    bulid_internal_links # gets all other internal inks on website
    obtain_page_data
  end

  def push_internal_links
    body = @doc.css('div.field-item.even').to_s
    unprocessed_hrefs = body.split('href="')
    unprocessed_hrefs.shift # drops first element

    unprocessed_hrefs.each do |href|
      evaluate_href(href.split('"')[0])
    end

    @internal_links = @internal_links.uniq
  end

  def evaluate_href(href)
    return if document_link?(href)
    return if external_link?(href)
    @internal_links.push(href) unless href.include?('#')
  end

  def document_link?(href)
    return true if href.include?('documents/') # works in this domain
    false
  end

  def external_link?(href)
    link_identifiers = ['http://', 'https://', 'mailto:']

    link_identifiers.each do |identifier|
      return true if href.include?(identifier)
    end

    false
  end

  def bulid_internal_links
    @internal_links.each do |page|
      begin
        create_page_doc(page: page)
        push_internal_links
      rescue StandardError => error
        warn "#{error};  METHOD  #{__callee__};  RESOURCE  #{page}"
        next
      end
    end
  end

  def obtain_page_data
    @internal_links.each do |page|
      begin
        create_page_doc(page: page)
        @page_contents[page] = evaluate_page
        @page_titles[page] = establish_title.gsub('&amp;', '&')
      rescue StandardError => error
        warn "#{error};  METHOD  #{__callee__};  RESOURCE  #{page}"
        next
      end
    end
  end

  def evaluate_page
    body = @doc.css('div.field-item.even')
    body.search('img', 'div.alert.alert-info', 'a.btn.btn-primary.btn-xs', 'br',
                'hr').remove
    body = body.to_s
    unprocessed_hrefs = body.split('href="')
    unprocessed_hrefs.shift # drops first element
    drive_links = []

    unprocessed_hrefs.each do |href|
      drive_links.push(href.split('"')[0]) if document_link?(href.split('"')[0])
    end

    body = swap_links(drive_links, body)
    # body = Nokogiri::HTML(body)
    # body.search('h1').remove
    body = body.to_s
    body
  end

  def swap_links(drive_links, body)
    drive_links.each do |link|
      decoded_link = URI.decode(link)
      file_id = @drive_file_ids["elecint0#{decoded_link}"]
      next if file_id.nil?
      fixed_link = "#{DRIVE_BASE_LINK}#{file_id}"
      body = body.gsub(link, fixed_link)
    end

    body = body.gsub('</a>', "</a>#{NEW_LINE}")
    body
  end

  def establish_title
    titles = @doc.css('h1')
    first = titles[0].to_s
    return first.split('>')[1].split('<')[0] unless first.include?'<h1> </h1>'
    second = titles[1].to_s.split('>')[1].split('<')[0]
    second
  end
end
