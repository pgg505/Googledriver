#!/usr/bin/env ruby

require "./analyser.rb"

# uploader = Uploader.new()
# fold1 = uploader.upload_folder("First", hex_colour: "#00FF00")
# fold2 = uploader.upload_folder("Second", location: fold1)
# change = uploader.update_file_permission(fold1, "pgg505@york.ac.uk")
# file1 = uploader.upload_file("test.pdf", "A", fold2)
# file2 = uploader.upload_file("flower.jpeg", "B", fold1)
# text = uploader.upload_file("store.rb", "Test")

analyser = Analyser.new()
analyser.temp()
