# Googledriver 0.0.2
Authorize a Google account and upload files to its Drive.
## Requirements
Googledriver was developed using Ruby 2.3.1 and is untested on other versions.
This gem has the following runtime dependencies which can be managed using
bundler:
* [json](https://rubygems.org/gems/json) (developed using 2.1.0)
* [oauth2](https://rubygems.org/gems/oauth2) (developed using 1.4.0)
* [rest-client](https://rubygems.org/gems/rest-client) (developed using 2.0.2)

Install the gem using the following Bash command command:
```bash
sudo gem install googledriver
```
Then add to your Ruby programs as needed:
```ruby
require 'googledriver'
```
## Example Method Usage
Creating an Uploader object:
```ruby
uploader = Googledriver::Uploader.new('/home/usr/client_secret.json')
```
Creating an Authorizer object:
```ruby
authorizer = Googledriver::Authorizer.new('/home/usr/client_secret.json')
# Note that the Uploader class creates an Authorizer object so there is no need
# to create both manually if you wish to perform an upload.
```
Uploading a filesystem to Google Drive:
```ruby
uploader.upload_filesystem(directory: '/home/usr/file_sys', upload_dest: 'root')
```
Uploading a file to Google Drive:
```ruby
uploader.upload_file('/home/usr/image.jpeg', 'image_name', location: 'root')
# Note that location can be a folder id if the desired location for the file
# is not root.
```
Update the name of a file in Google Drive:
```ruby
uploader.update_file_metadata('0x123abc', 'name', 'new_name')
# Note that the second parameter is the metadata element to be updated so only
# certain strings are allowed.
```
Sharing a file with a user or group in Google Drive:
```ruby
uploader.update_file_permission('0x123abc', 'sharewithme@gmail.com')
```
## Example Program
```ruby
require 'googledriver'

uploader = Googledriver::Uploader.new('/home/usr/client_secret.json')
uploader.upload_filesystem(directory: '/home/usr/file_sys', upload_dest: 'root')
uploader.archive_file_ids
```
