#!/usr/bin/env ruby

require "./uploader.rb"

uploader = Uploader.new()
file_id = uploader.upload_file("flower.jpeg")
p "Metadata: " + uploader.get_file_metadata(file_id)
permission_id = uploader.get_file_permissionid(file_id)
puts "\n"
p "Permission: " + uploader.get_file_permission(file_id, permission_id)
update = uploader.update_file_metadata(file_id)
p "Metadata: " + uploader.get_file_metadata(file_id)
