class DbFile < ActiveRecord::Base
  # This is the model for database storage
  
  # Polymorphic so that many models can use this class to store binary data
  belongs_to :owner, :polymorphic => true
  # Note: We are constrained by the database to split files into 200kbyte partitions
end