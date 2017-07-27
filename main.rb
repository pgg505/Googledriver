require "./uploader.rb"

begin
  start_time = Time.now
  uploader = Uploader.new
  uploader.upload_filesystem(upload_dest: "root", current_dir: "elecint0/documents/")
  File.open("file_ids.txt", "w")
  File.write("file_ids.txt", uploader.file_ids)
  File.open("folder_ids.txt", "w")
  File.write("folder_ids.txt", uploader.folder_ids)
  run_time = Time.now - start_time
  puts run_time.to_s + "s"
rescue => error
  p error
end
