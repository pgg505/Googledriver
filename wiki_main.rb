require './web_scraper.rb'
require './wiki_builder.rb'

scraper = WebScraper.new('https://intranet.elec.york.ac.uk/', 'extexam11',
                         'turquoisehorse78')
p scraper.drive_links
WikiBuilder.new(scraper.page_contents)
