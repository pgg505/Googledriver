require "./uploader.rb"

class Analyser
  '''Analyses an Ubuntu file system.'''

  def initialize()
    @uploader = Uploader.new()
  end

  def temp()
    Dir['**/*'].each do |f|
      if f.count("/") == 0 then
        if f.count(".") == 0 then
          @uploader.upload_folder(f)
        else
          p f
          @uploader.upload_file(f, f)
        end
      end
    end
  end
end
