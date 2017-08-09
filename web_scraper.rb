require 'json'
require 'nokogiri'
require 'open-uri'

# Scrapes a Drupal website
class WebScraper
  NEW_LINE = '<p></p>'.freeze # used to emulate line breaks
  attr_reader :page_contents, :drive_links

  def initialize(initial_uri, username, password)
    build_file_ids
    @base_uri = initial_uri
    @user = username
    @key = password
    update_doc
    @internal_links = []
    @drive_links = []
    @page_contents = {} # hash of pages to markup code
    scrape_website
  end

  def build_file_ids
    file_content = File.read('drive_file_ids.json')
    puts @drive_file_ids = JSON.parse(file_content)
  end

  def update_doc(page: '')
    new_page = open(@base_uri + page,
                    http_basic_authentication: [@user, @key])
    @doc = Nokogiri::HTML(new_page)
  end

  def scrape_website
    add_internal_links # gets internal links on homepage
    build_internal_links # gets all other internal links
    build_page_contents
  end

  def add_internal_links
    body = @doc.css('div.field-item.even').to_s
    unprocessed_hrefs = body.split('href="')
    unprocessed_hrefs.shift

    unprocessed_hrefs.each do |href|
      evaluate_href(href.split('"')[0])
    end

    @internal_links = @internal_links.uniq
  end

  def evaluate_href(href)
    return if external_link?(href)

    if document_link?(href)
      @drive_links.push(href)
      return
    end

    @internal_links.push(href) unless href.include?('#')
  end

  def external_link?(href)
    link_identifiers = ['http://', 'https://', 'mailto:']

    link_identifiers.each do |identifier|
      return true if href.include?(identifier)
    end

    false
  end

  def document_link?(href)
    return true if href.include?('documents/')
    false
  end

  def build_internal_links
    @internal_links.each do |page|
      begin
        update_doc(page: page)
        add_internal_links
      rescue StandardError => e
        warn e.to_s + '   PAGE   ' + page
      end
    end
  end

  def build_page_contents
    @internal_links.each do |page|
      begin
        update_doc(page: page)
        page_contents[page] = evaluate_page
      rescue StandardError => e # using error handling for flow control here
        warn e.to_s + '   PAGE   ' + page
      end
    end
  end

  def evaluate_page # cannot evaluate an uncreated page so gets error here
    fix_drive_links
    unprocessed_body = @doc.css('div.field-item.even')
    unprocessed_body.search('img', 'div.alert.alert-info',
                            'a.btn.btn-primary.btn-xs', 'br', 'hr').remove
    unprocessed_body = unprocessed_body.to_s.gsub('</a> ', "</a> #{NEW_LINE}")
    body = unprocessed_body.gsub('</h1>', '</h1>' + NEW_LINE)
    body
  end

  def fix_drive_links
    @drive_links = @drive_links.uniq

    @drive_links.each do |drive_link|
      fixed_link = @drive_file_ids[drive_link]
      @doc = @doc.gsub(drive_link, fixed_link) unless fixed_link.nil?
      puts "#{drive_link} -> #{fixed_link}" unless fixed_link.nil?
    end
  end
end
