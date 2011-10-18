module CarrierWave
  module Storage

    # Database storage - puts the file contents in a database table
    class Database < Abstract

      def initialize(*args,&block)
         super
          puts "**********Initialise storage***************"
          puts args.inspect
          
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
        puts "file #{file.inspect}"
        puts "self #{self.inspect}"
        temp_data = file.read
        
        f = CarrierWave::Storage::Database::File.new(uploader, self, uploader.store_path)
        f.store(temp_data)
        f
        puts "/Store--------------"
        
      end

      def retrieve!(identifier)
        
        puts "called retrieve--------------"
        puts "identifier #{identifier}"
        CarrierWave::Storage::Database::File.new(uploader, self, uploader.store_path(identifier))
        # Ported from paperclip
        # tempfile = Tempfile.new (uploader.model.name)
        #        puts uploader.model.inspect
        #        tempfile.write uploader.model.read_file
        #(uploader.model[uploader.mounted_as])
       
        # puts uploader.inspect
        # outp = CarrierWave::SanitizedFile.new(tempfile)
        # path = "#{uploader.cache_dir}/#{identifier}.tmp"
        #         outp.move_to(path)
        # puts "end retrieve - ctype: #{outp.inspect}"
        # outp
        
      end
      
      class File
        def initialize(uploader, base, path)
          @uploader = uploader
          @path = path
          @base = base
        end
          
        # Returns the current path of the file 
        def path
          @path
        end

        # Reads the contents of the file
        #
        # === Returns
        #
        # [String] contents of the file
        #
        def read
          current_data
        end
        
        # Remove the file
        def delete
          destroy_file
        end

        # Returns the url on Amazon's S3 service
        #
        # === Returns
        #
        # [String] file's url
        #
        def url
          "url pending implementation"
        end

        def store(file)
          each_slice(file) do |start, finish|
            @uploader.model.db_files.create!(:data => file.slice(start, finish))
          end
          
          slices = find_slices(file)
          # slices.each do |slice|
          #            db_file = @uploader.model.db_files.build
          #            db_file.data = file.slice(*slice)
          #            db_file.save!
          # #                self.class.update_all ['db_file_id = ?', self.db_file_id = db_file.id], ['id = ?', id]
          #           end
        end

        def content_type
          "ctype pending implementation"
        end

        def content_type=(type)
          "ctype pending implementation"
        end
        
        private
          # Gets the current data from the database
          def current_data
            @uploader.model.db_files.map(&:data).join
          end
          
          # Destroys the file.  Called in the after_destroy callback
          def destroy_file
            @uploader.model.db_files.each do |db_file|
              db_file.delete
            end
          end
          
          def each_slice(data)
            max_part_size = 200.kilobytes
            max_part_size ||=1.megabyte
            beginning =0;
            left = data.size
            
          end
          
          def find_slices(data)
            slices = []
            max_part_size = 200.kilobytes
            max_part_size ||=1.megabyte
            beginning =0;
            left = data.size
            while  left>0
              part_size = [left, max_part_size].min
              slices << [beginning, part_size]
              beginning += part_size
              left -= part_size
            end
            
            slices
          end
      end
    end # Database 
  end # Storage
end # CarrierWave

class DocumentUploader < CarrierWave::Uploader::Base
  
  storage CarrierWave::Storage::Database
  def initialize(*args,&block)
     super
      puts "**********Initialise uploader***************"
      args.inspect
      # uploader.inspect
      
  end
  # Override the directory where uploaded files will be stored
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

end
