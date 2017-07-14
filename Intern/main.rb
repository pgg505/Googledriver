#!/usr/bin/env ruby

require "./uploader.rb"

uploader = Uploader.new()
file_id = uploader.upload_file("flower.jpeg")
update = uploader.update_file_metadata(file_id, "name", "flower")
updates = uploader.update_file_permission(file_id, "pgiordano97@gmail.com")
puts metad = uploader.get_file_metadata(file_id)
