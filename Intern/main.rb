#!/usr/bin/env ruby

require "./uploader.rb"

uploader = Uploader.new()

file_id = uploader.upload_file("test.pdf", "alk")
p meta = uploader.get_file_metadata(file_id)
#p update = uploader.update_file_metadata(file_id, "name", "Plan")

#update = uploader.update_file_metadata(file_id, "parents", "0B9FK_ZzXJlazYlpYdExRU3lGSGM")
#updates = uploader.update_file_permission(file_id, "pgg505@york.ac.uk", "writer")

#p fold_id = uploader.upload_folder()
