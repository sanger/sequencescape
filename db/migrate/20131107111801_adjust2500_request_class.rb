class Adjust2500RequestClass < ActiveRecord::Migration

  # Use deployment project to deploy

  def self.up
    RequestType.find(:all, :conditions=>'name LIKE "%_hiseq_2500_single_end_sequencing"').each do |request_type|
      request_type.update_attributes!(:request_class_name=>'HiSeq2500SequencingRequest')
    end
  end

  def self.down
    RequestType.find(:all, :conditions=>'name LIKE "%_hiseq_2500_single_end_sequencing"').each do |request_type|
      request_type.update_attributes!(:request_class_name=>'HiSeqSequencingRequest')
    end
  end
end
