Gem::Specification.new do |s|
  s.name = 'googledriver'
  s.version = '0.0.2'
  s.date = '2017-08-29'
  s.summary = 'Authorize a Google account and upload files to its Drive.'
  s.author = 'Peter Giordano'
  s.email = 'pgg505@york.ac.uk'
  s.files = ['lib/googledriver.rb', 'lib/googledriver/uploader.rb',
             'lib/googledriver/authorizer.rb']
  s.homepage = 'http://rubygems.org/gems/googledriver'
  s.license = 'MIT'

  s.add_dependency('json', '~> 2.1', '>= 2.1.0')
  s.add_dependency('oauth2', '~> 1.4', '>= 1.4.0')
  s.add_dependency('rest-client', '~> 2.0', '>= 2.0.2')

  s.add_development_dependency('rdoc', '~> 5.1', '>= 5.1.0')
  s.add_development_dependency('rubocop', '~> 0.49.1')

  s.required_ruby_version = '>= 2.0.0'
end
