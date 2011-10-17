module CarrierWave
  module Storage

    # Database storage - puts the file contents in the uploader's database field
    class DBStorage < Abstract
      
      def initialize(*args,&block)
         super
          puts "**********Initialise storage***************"
          args.inspect
          # uploader.inspect
          
      end
      
      def store!(file)
      # file storage:
        # path = ::File.expand_path(uploader.store_path, uploader.root)
        #         file.copy_to(path, uploader.permissions)
      # gridfs storage
        # stored = CarrierWave::Storage::GridFS::File.new(uploader, uploader.store_path)
        #                stored.write(file)
        #                stored
        
        # We have the uploader, and the uploader.store_path
        
        puts "Store---------------"
        # file.inspect
        # write_attribute(uploader.mounted_as,file.read)
        uploader.model.write_uploader(uploader.mounted_as,file.read)
        # uploader.inspect
        # uploader_options.inspect
        # self.data = file_field.read
        puts "/Store--------------"
        
      end

      def retrieve!(identifier)
        # If the identifier is a binary file, then return it as an attachment?
        
        puts "called retrieve--------------"
        puts "id #{identifier}"
        # Ported from paperclip
        tempfile = Tempfile.new (uploader.model.name)
        puts uploader.model.inspect
        tempfile.write uploader.model.read_file
        #(uploader.model[uploader.mounted_as])
       
        # puts uploader.inspect
        outp = CarrierWave::SanitizedFile.new(tempfile)
        # path = "#{uploader.cache_dir}/#{identifier}.tmp"
        #         outp.move_to(path)
        puts "end retrieve - ctype: #{outp.inspect}"
        outp
        
      end

    end # Database 
  end # Storage
end # CarrierWave

class DocumentUploader < CarrierWave::Uploader::Base

  # Include RMagick or ImageScience support
  #     include CarrierWave::RMagick
  #     include CarrierWave::ImageScience

  
  storage CarrierWave::Storage::DBStorage
  
  # Override the directory where uploaded files will be stored
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  # Provide a default URL as a default if there hasn't been a file uploaded
  #     def default_url
  #       "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  #     end

  # Process files as they are uploaded.
  #     process :scale => [200, 300]
  #
  #     def scale(width, height)
  #       # do something
  #     end

  # Create different versions of your uploaded files
  #     version :thumb do
  #       process :scale => [50, 50]
  #     end

  # Add a white list of extensions which are allowed to be uploaded,
  # for images you might use something like this:
  #     def extension_white_list
  #       %w(jpg jpeg gif png)
  #     end

  # Override the filename of the uploaded files
  #     def filename
  #       "something.jpg" if original_filename
  #     end

end
