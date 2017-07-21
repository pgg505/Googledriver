#!/usr/bin/env ruby

require "./uploader.rb"
require "./mandator.rb"

begin
  mandator = Mandator.new
  mandator.build_hash(starting_dir: "elecint0/documents/")
  # @uploader = Uploader.new
  # @uploader.upload_filesystem
rescue => error
  p error
end
