require './web_scraper.rb'
require './wiki_builder.rb'

scraper = WebScraper.new
puts 'Internal links '
p scraper.internal_links.length

# builder = WikiBuilder.new(page_title, page_body)
# puts 'x0'
# puts builder.upload_page_content
# puts 'x1'
# puts builder.get_page_content(page_title)
