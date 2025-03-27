# frozen_string_literal: true
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
        attr_reader :path

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
          @uploader.model.db_files.create!(data: file)
        end

        # Error handling should help if uploader was mounted to a model with no content_type
        def content_type
          @uploader.model.content_type if @uploader.model.respond_to? :content_type
        end

        def content_type=(type)
          @uploader.model.content_type = type unless type.nil? if @uploader.model.respond_to? :content_type
        end

        private

        # Gets the current data from the database
        # Data used to be chunked into 200kb size fragments. This is no longer the
        # case, but the older files have not been updated.
        def current_data
          @uploader.model.db_files.pluck(:data).join
        end

        # Destroys the file. Called in the after_destroy callback
        def destroy_file
          @uploader.model.db_files.each(&:delete)
        end
      end
    end
  end
end

class PolymorphicUploader < CarrierWave::Uploader::Base
  def initialize(*args, &)
    super
  end

  def exists?
    @column.blank?
  end

  storage CarrierWave::Storage::DirectDatabase
  cache_storage CarrierWave::Storage::File

  # This is where files are stored on upload. We are using callbacks to empty it after upload
  def self.cache_dir
    "#{Rails.root}/tmp/uploads"
  end

  delegate :cache_dir, to: :class

  before :store, :remember_cache_id
  after :store, :delete_tmp_dir

  # store! nils the cache_id after it finishes so we need to remember it for deletion
  def remember_cache_id(_new_file)
    @cache_id_was = cache_id
  end

  def delete_tmp_dir(_new_file)
    # make sure we don't delete other things accidentally by checking the name pattern
    FileUtils.rm_rf(File.join(cache_dir, @cache_id_was)) if @cache_id_was.present? && @cache_id_was =~ /\A[\d-]*\z/
  end
end
