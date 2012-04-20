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
      line = __LINE__ + 1
      class_eval(%Q{
        mount_uploader data, PolymorphicUploader, :mount_on => serialization_column
      }, __FILE__, line)
    end
    
  end
end