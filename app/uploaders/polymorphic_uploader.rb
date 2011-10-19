module CarrierWave
  module Storage
    # Database storage - puts the file contents in a database table
    class DirectDatabase < Abstract
      # Store: Takes a file object, passes it to a file wrapper class which handles storage in the DB
      def store!(file)
        temp_data = file.read
        f = CarrierWave::Storage::Database::File.new(uploader, self, uploader.store_path)
        f.store(temp_data)
        f
      end

      # Retrieve: Returns a file wrapper which accesses the database via the passed model
      def retrieve!(identifier)
        CarrierWave::Storage::Database::File.new(uploader, self, uploader.store_path(identifier))
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
        def read
          current_data
        end
        
        # Remove the file
        def delete
          destroy_file
        end

        # Returns the url
        def url
          "url pending implementation"
        end

        # Stores the file in the DbFiles model - split across many rows if size > 200KB 
        def store(file)
          each_slice(file) do |start, finish|
            @uploader.model.file.create!(:data => file.slice(start, finish))
          end
          
          # Old code from attachment_fu: doesn't seem to be needed
          # #  self.class.update_all ['db_file_id = ?', self.db_file_id = db_file.id], ['id = ?', id]
        end

        # This is also duplicated in the Document model
        def content_type
          @uploader.model.content_type
        end

        def content_type=(type)
          @uploader.model.content_type=type unless type.nil?
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
          
          # Yields the partitions for the file with the max_part_size boundary
          def each_slice(data)
            max_part_size = 200.kilobytes
            beginning =0;
            left = data.size
            while left>0
              part_size = [left, max_part_size].min
              yield beginning, part_size
              beginning += part_size
              left -= part_size
            end
          end
      end
    end # Database 
  end # Storage
end # CarrierWave
class PolymorphicUploader < CarrierWave::Uploader::Base

  # Choose what kind of storage to use for this uploader
  storage :file
  #     storage :s3

  # Override the directory where uploaded files will be stored
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

end
