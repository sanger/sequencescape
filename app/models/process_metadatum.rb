class ProcessMetadatum < ActiveRecord::Base

  belongs_to :process_metadatum_collection
  
  validates_presence_of :value
  validates_uniqueness_of :key, scope: :process_metadatum_collection_id

  def to_h
    { key => value}
  end
end
