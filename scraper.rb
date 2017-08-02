require 'open-uri'
require 'nokogiri'

# Scrapes the Drupal website
class Scraper
  attr_reader :title, :links, :body

  def initialize
    uri = 'https://intranet.elec.york.ac.uk'
    html = open(uri, http_basic_authentication: %w[extexam11 turquoisehorse78])
    @doc = Nokogiri::HTML(html)
    @title = obtain_title
    processed_links = process_links(obtain_hrefs, obtain_links)
    @links = finalise_links(processed_links)
    obtain_body
  end

  def obtain_title
    temp_string = @doc.css('title')
    title = temp_string.to_s.split('>')[1].chomp('</title')
    title
  end

  def obtain_links
    temp_string = @doc.css('ul.menu.nav').css('li')
    links = temp_string
    puts links
  end

  def obtain_body
    temp_string = @doc.css('div.field-item.even')

    temp_string.each do |tag|
      puts tag
    end
  end
end
