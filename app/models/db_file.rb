# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2015 Genome Research Ltd.

class DbFile < ActiveRecord::Base
  # This is the model for database storage

  # Polymorphic so that many models can use this class to store binary data
  belongs_to :owner, :polymorphic => true
  # Note: We are constrained by the database to split files into 200kbyte partitions

  # This module will set up all required associations and allow mounting "polymorphic uploaders"
  module Uploader
    def self.extended(base)
      base.has_many :db_files, :as => :owner, :dependent => :destroy
    end

    # Mount an uploader on the specified 'data' column
    #  - you can use the serialisation option for saving the filename in another column - see Carrierwave
    def has_uploaded(data, options)
      serialization_column = options.fetch(:serialization_column, "#{data}")

      class_eval do
        mount_uploader data, PolymorphicUploader, :mount_on => serialization_column
      end

    end

  end
end
