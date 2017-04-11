# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2013,2014,2015 Genome Research Ltd.

class QcFile < ActiveRecord::Base
  extend DbFile::Uploader
  include Uuid::Uuidable

  module Associations
    # Adds accessors for named fields and attaches documents to them

    def has_qc_files
      line = __LINE__ + 1
      class_eval("
        has_many(:qc_files, {:as => :asset, :dependent => :destroy })

        def add_qc_file(file, filename=nil)
          opts = {:uploaded_data => {:tempfile=>file, :filename=>filename}}
          opts.merge!(:filename=>filename) unless filename.nil?
          qc_files.create!(opts) unless file.blank?
        end

        def update_qc_values_with_parser(parser)
          true
        end
      ", __FILE__, line)
    end
  end

  belongs_to :asset, polymorphic: true
  validates_presence_of :asset

  # Handle some of the metadata with this callback
  before_save :update_document_attributes
  after_save :store_file_extracted_data, if: :parser

  # CarrierWave uploader - gets the uploaded_data file, but saves the identifier to the "filename" column
  has_uploaded :uploaded_data, serialization_column: 'filename'

  # Method provided for backwards compatibility
  def current_data
    uploaded_data.read
  end

  def retrieve_file
    begin
      uploaded_data.cache!(uploaded_data.file)
      yield(uploaded_data)
    ensure
      # We can't actually delete the cache file here, as the send_file
      # operation happens asynchronously. Instead we can use:
      # PolymorphicUploader.clean_cached_files!
      # This cleans the last 24h worth of files, so should be a daily
      # cron
    end
  end

  private

  def parser
    @parser ||= Parsers.parser_for(filename, content_type, current_data)
  end

  def store_file_extracted_data
    return if parser.nil?
    asset.update_qc_values_with_parser(parser)
  end

  # Save Size/content_type Metadata
  def update_document_attributes
    if uploaded_data.present?
      self.content_type = uploaded_data.file.content_type
      self.size = uploaded_data.file.size
    end
  end
end
