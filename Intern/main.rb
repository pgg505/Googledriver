require "./uploader.rb"
require "./mandator.rb"

begin
  # ARGV[0]
  mandator = Mandator.new
  mandator.build_groups_hash("groups.txt")
  mandator.build_htaccess_hash(starting_dir: "elecint0/documents/")
  # start_time = Time.now
  # @uploader = Uploader.new
  # @uploader.upload_filesystem(current_dir: "elecint0/documents/")
  # end_time = Time.now
  # exec_time = end_time - start_time
  # puts "Upload time: " + exec_time.to_s
rescue => error
  p error
end
