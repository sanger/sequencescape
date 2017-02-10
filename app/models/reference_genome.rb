# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2014,2015 Genome Research Ltd.

class ReferenceGenome < ActiveRecord::Base
  extend Attributable::Association::Target
  include Api::ReferenceGenomeIO::Extensions
  include Uuid::Uuidable
  include SharedBehaviour::Named

  has_many :studies
  has_many :samples
  validates_uniqueness_of :name, message: 'of reference genome already present in database', allow_blank: true

  module Associations
    def self.included(base)
      base.validates_presence_of :reference_genome_id
      base.validates_numericality_of :reference_genome_id, greater_than: 0, message: 'appears to be invalid'
      base.belongs_to :reference_genome
    end
  end
end
