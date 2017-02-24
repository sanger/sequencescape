# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2011,2012 Genome Research Ltd.
class Program < ActiveRecord::Base
  extend Attributable::Association::Target

  default_scope ->() { order(:name) }

  validates_presence_of :name
  validates_uniqueness_of :name, message: 'of programs already present in database'

  has_many :study_metadata, class_name: 'Study::Metadata'
  has_many :studies, through: :study_metadata

  module Associations
    def self.included(base)
      base.validates_presence_of :program_id
      base.belongs_to :program
    end
  end
end
