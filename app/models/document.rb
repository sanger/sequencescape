# frozen_string_literal: true
require 'carrierwave'

class Document < ApplicationRecord # rubocop:todo Style/Documentation
  extend DbFile::Uploader

  module Associations # rubocop:todo Style/Documentation
    # Adds accessors for named fields and attaches documents to them

    def has_uploaded_document(field, differentiator: field.to_s) # rubocop:todo Metrics/MethodLength
      # Options
      #  differentiator - this is a string used to separate multiple documents related to your model
      #     for example, you can have both a "generated" and an "uploaded" document in one Sample Manifest
      line = __LINE__ + 1
      class_eval(
        "
        has_one(
          :#{field}_document, ->(){ where(documentable_extended: differentiator) },
          class_name: \"Document\", as: :documentable, dependent: :destroy
          )

        def #{field}
          self.#{field}_document
        end

        def #{field}=(file)
          create_#{field}_document(uploaded_data: file, documentable_extended: '#{differentiator}') unless file.blank?
        end
      ",
        __FILE__,
        line
      )
    end
  end

  # Polymorphic relationship
  belongs_to :documentable, polymorphic: true

  # CarrierWave uploader - gets the uploaded_data file, but saves the identifier to the "filename" column
  has_uploaded :uploaded_data, serialization_column: 'filename'

  # Method provided for backwards compatibility
  def current_data
    uploaded_data.read
  end

  # Handle some of the metadata with this callback
  before_save :update_document_attributes

  private

  # Save Size/content_type Metadata
  def update_document_attributes
    if uploaded_data.present?
      self.content_type = uploaded_data.file.content_type
      self.size = uploaded_data.file.size
    end
  end
end
