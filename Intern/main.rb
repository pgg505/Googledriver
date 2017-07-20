#!/usr/bin/env ruby

require "./uploader.rb"

begin
  @uploader = Uploader.new()
  @uploader.upload_filesystem
rescue => error
  p error
end
