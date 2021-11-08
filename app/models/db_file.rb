# frozen_string_literal: true
class DbFile < ApplicationRecord # rubocop:todo Style/Documentation
  # This is the model for database storage

  # Polymorphic so that many models can use this class to store binary data
  belongs_to :owner, polymorphic: true

  # NOTE: We are constrained by the database to split files into 200kbyte partitions

  # This module will set up all required associations and allow mounting "polymorphic uploaders"
  module Uploader
    def self.extended(base)
      base.has_many :db_files, as: :owner, dependent: :destroy # rubocop:todo Rails/HasManyOrHasOneDependent
    end

    # Mount an uploader on the specified 'data' column
    #  - you can use the serialisation option for saving the filename in another column - see Carrierwave
    def has_uploaded(data, options)
      serialization_column = options.fetch(:serialization_column, data.to_s)

      class_eval { mount_uploader data, PolymorphicUploader, mount_on: serialization_column }
    end
  end
end
