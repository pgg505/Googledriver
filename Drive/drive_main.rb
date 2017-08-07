require './drive_uploader.rb'

begin
  start_time = Time.now
  uploader = DriveUploader.new
  uploader.upload_filesystem(upload_dest: 'root',
                             current_dir: 'elecint0/documents/')
  puts 'Failed uploads ' + uploader.failed_uploads.to_s
  File.open('file_ids.txt', 'w')
  File.write('file_ids.txt', uploader.file_ids)
  File.open('folder_ids.txt', 'w')
  File.write('folder_ids.txt', uploader.folder_ids)
  run_time = Time.now - start_time
  puts 'Run time ' + run_time.to_s + 's'
rescue StandardError => e
  puts e
end
