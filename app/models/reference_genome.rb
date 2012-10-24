class ReferenceGenome < ActiveRecord::Base
  extend Attributable::Association::Target

  has_many :studies
  has_many :samples
  validates_uniqueness_of :name, :message => "of reference genome already present in database", :allow_blank => true
  named_scope :sorted_by_name , :order => "name ASC"  

  module Associations
    def self.included(base)
      base.validates_presence_of :reference_genome_id
      base.validates_numericality_of :reference_genome_id, :greater_than => 0, :message => 'appears to be invalid'
      base.belongs_to :reference_genome
    end
  end
end
