require "./uploader.rb"

begin
  start_time = Time.now

  @uploader = Uploader.new
  @uploader.upload_filesystem("elecint0/documents/private/", "elecint0/documents/private")
  puts "Generated ids of uploaded folders:\n"
  p folder_to_id_hash = @uploader.get_folder_ids
  puts "\n"

  end_time = Time.now
  exec_time = end_time - start_time
  puts "Run time was " + exec_time.to_s + "s"
rescue => error
  p error
end
