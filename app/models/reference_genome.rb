class ReferenceGenome < ApplicationRecord # rubocop:todo Style/Documentation
  extend Attributable::Association::Target
  include Api::ReferenceGenomeIO::Extensions
  include Uuid::Uuidable
  include SharedBehaviour::Named

  has_many :studies
  has_many :samples
  validates :name, uniqueness: { message: 'of reference genome already present in database',
                                 allow_blank: true,
                                 case_sensitive: false }
  broadcast_with_warren

  module Associations # rubocop:todo Style/Documentation
    def self.included(base)
      base.validates_presence_of :reference_genome_id
      base.validates_numericality_of :reference_genome_id, greater_than: 0, message: 'appears to be invalid'
      base.belongs_to :reference_genome
    end
  end
end
