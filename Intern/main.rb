#!/usr/bin/env ruby

require "./uploader.rb"

uploader = Uploader.new()
fold1 = uploader.upload_folder("First", hex_colour: "#00FF00")
fold2 = uploader.upload_folder("Second", hex_colour: "#00FF00")
update1 = uploader.update_file_permission(fold1, "pgg505@york.ac.uk")
update2 = uploader.update_file_permission(fold2, "pgiordano97@gmail.com")
file1 = uploader.upload_file("test.pdf", "A", fold1)
file2 = uploader.upload_file("flower.jpeg", "B", fold2)
