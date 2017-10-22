# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2014,2015 Genome Research Ltd.

require 'carrierwave'

module CarrierWave
  module Storage
    # Database storage - puts the file contents in a database table
    class DirectDatabase < Abstract
      # Store: Takes a file object, passes it to a file wrapper class which handles storage in the DB
      def store!(file)
        f = CarrierWave::Storage::DirectDatabase::File.new(uploader, self, uploader.store_path)
        f.store(file.read)
        f
      end

      # Retrieve: Returns a file wrapper which accesses the database via the passed model
      def retrieve!(identifier)
        CarrierWave::Storage::DirectDatabase::File.new(uploader, self, uploader.store_path(identifier))
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

        delegate :size, to: :current_data

        # Reads the contents of the file
        def read
          current_data
        end

        # Remove the file
        def delete
          destroy_file
        end

        # Would returns the url
        def url
          raise NotImplementedError, 'Files are stored in the database, so are not available directly through a URL'
        end

        # Stores the file in the DbFiles model - split across many rows if size > 200KB
        def store(file)
          each_slice(file) do |start, finish|
            @uploader.model.db_files.create!(data: file.slice(start, finish))
          end

          # Old code from attachment_fu: doesn't seem to be needed
          # #  self.class.update_all ['db_file_id = ?', self.db_file_id = db_file.id], ['id = ?', id]
        end

        # Error handling should help if uploader was mounted to a model with no content_type
        def content_type
          @uploader.model.content_type if @uploader.model.respond_to? :content_type
        end

        def content_type=(type)
          if @uploader.model.respond_to? :content_type
            @uploader.model.content_type = type unless type.nil?
          end
        end

        private

          # Gets the current data from the database
          def current_data
            @uploader.model.db_files.map(&:data).join
          end

          # Destroys the file. Called in the after_destroy callback
          def destroy_file
            @uploader.model.db_files.each do |db_file|
              db_file.delete
            end
          end

          # Yields the partitions for the file with the max_part_size boundary
          def each_slice(data)
            max_part_size = 200.kilobytes
            beginning = 0;
            left = data.size
            while left > 0
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
  def initialize(*args, &block)
    super
  end

  def exists?
    @column.blank?
  end

  storage CarrierWave::Storage::DirectDatabase

  # This is where files are stored on upload. We are using callbacks to empty it after upload
  def self.cache_dir
     "#{Rails.root}/tmp/uploads"
  end

  def cache_dir
    self.class.cache_dir
  end

  before :store, :remember_cache_id
  after :store, :delete_tmp_dir

  # store! nils the cache_id after it finishes so we need to remember it for deletion
  def remember_cache_id(_new_file)
    @cache_id_was = cache_id
  end

  def delete_tmp_dir(_new_file)
    # make sure we don't delete other things accidentally by checking the name pattern
    if @cache_id_was.present? && @cache_id_was =~ /\A[\d]{8}\-[\d]{4}\-[\d]+\-[\d]{4}\z/
      FileUtils.rm_rf(File.join(cache_dir, @cache_id_was))
    end
  end
end
