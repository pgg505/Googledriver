require 'json'
require 'oauth2'
require 'rest-client'
require File.dirname(__FILE__) + '/googledriver/uploader.rb'
require File.dirname(__FILE__) + '/googledriver/authorizer.rb'

# This module is used to authorize a Google account and upload files to its
# Drive. It also supports the management of uploaded files through changing the
# permissions and metadata of a file. Before use, a secrets file must be
# downloaded by following the wizard here
# https://console.developers.google.com/start/api?id=drive. See README.md on the
# gem's homepage for usage guide.

module Googledriver; end
