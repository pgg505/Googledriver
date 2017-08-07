require 'open-uri'
require 'nokogiri'

# Scrapes the Drupal website
class WebScraper
  NEW_LINE = '<p></p>'.freeze
  HOME_PAGE = 'https://intranet.elec.york.ac.uk/'.freeze
  attr_reader :title, :body, :internal_links

  def initialize
    uri = HOME_PAGE
    html = open(uri, http_basic_authentication: %w[extexam11 turquoisehorse78])
    @doc = Nokogiri::HTML(html)
    @internal_links = []
    build_internal_links # pushes to internal links

    @internal_links.each do |page|
      begin
        new_uri = HOME_PAGE << page
        html = open(new_uri,
                    http_basic_authentication: %w[extexam11 turquoisehorse78])
        @doc = Nokogiri::HTML(html)
        build_internal_links
        @internal_links = @internal_links.uniq # removes duplicates
      rescue StandardError => e
        warn e
      end
    end
  end

  def build_internal_links
    unprocessed_body = @doc.css('div.field-item.even')
    body = unprocessed_body.to_s
    messy_hrefs = body.split('href="')
    messy_hrefs.shift # removes first element
    trimmed_hrefs = []

    messy_hrefs.each do |href|
      trimmed_hrefs.push(evaluate_href(href.split('"')[0]))
    end

    trimmed_hrefs
  end

  def evaluate_href(href)
    return href unless (href[0, 4] != 'http') && (href[0, 6] != 'mailto')
    return href unless href.include?('#') == false
    return generate_wiki_link(href) unless href.include?('documents/')
    generate_drive_link(href)
  end

  def generate_wiki_link(href)
    @internal_links.push(href)
    wiki_link = 'https://wikidev.york.ac.uk/display/CSRV813/' << href
    wiki_link
  end

  def generate_drive_link(href)
    drive_link = 'drive.google.com' << href # needs correcting
    drive_link
  end

  def obtain_body
    unprocessed_body = @doc.css('div.field-item.even')
    unprocessed_body.search('img', 'div.alert.alert-info',
                            'a.btn.btn-primary.btn-xs', 'br').remove
    body = unprocessed_body.to_s.gsub('</a>', '</a>' << NEW_LINE)
    body = body.gsub('</h1>', '</h1>' << NEW_LINE) # some basic formatting
    body
  end
end
