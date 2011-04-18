module Technoweenie # :nodoc:
  module AttachmentFu # :nodoc:
    module Backends
      # Methods for DB backed attachments
      module MultiDbFileBackend
        def self.included(base) #:nodoc:
          Object.const_set(:DbFile, Class.new(ActiveRecord::Base)) unless Object.const_defined?(:DbFile)
          base.has_many  :db_files, :class_name => '::DbFile', :foreign_key => 'document_id'
        end

        # Creates a temp file with the current db data.
        def create_temp_file
          write_to_temp_file current_data
        end
        
        # Gets the current data from the database
        def current_data
          db_files.map {|f| f.data }.join
        end
        
        protected
          # Destroys the file.  Called in the after_destroy callback
          def destroy_file
            db_files.each do |db_file|
              db_file.delete
            end
          end
          
          # Saves the data to the DbFile model
          def save_to_storage
            if save_attachment?
              data = temp_data
              slices = find_slices(data)
              slices.each do |slice|
                db_file = db_files.build
                db_file.data = data.slice(*slice)
                db_file.save!
#                self.class.update_all ['db_file_id = ?', self.db_file_id = db_file.id], ['id = ?', id]
              end
            end
            true
          end

          def find_slices(data)
            slices = []
            max_part_size = attachment_options[:max_part_size]
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
    end
  end
end
