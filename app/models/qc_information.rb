class QcInformation < ActiveRecord::Base
  extend DbFile::Uploader
  include Uuid::Uuidable

  set_table_name('qc_information')

  module Associations
    # Adds accessors for named fields and attaches documents to them

    def has_qc_information
      line = __LINE__ + 1
      class_eval(%Q{
        has_many(:qc_information_documents, :class_name => "QcInformation", :as => :asset, :dependent => :destroy
          )

        def qc_information
          self.qc_information_documents
        end

        def add_qc_information(file)
          qc_information_documents.create!(:uploaded_data => file) unless file.blank?
        end

      }, __FILE__, line)
    end

  end

  belongs_to :asset, :polymorphic => true

  # CarrierWave uploader - gets the uploaded_data file, but saves the identifier to the "filename" column
  has_uploaded :uploaded_data, {:serialization_column => "filename"}

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
        self.size    = uploaded_data.file.size
      end
    end
end

