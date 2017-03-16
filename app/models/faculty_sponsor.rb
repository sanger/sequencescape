# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

class FacultySponsor < ActiveRecord::Base
  include SharedBehaviour::Named
  extend Attributable::Association::Target

  default_scope { order(:name) }

  validates_presence_of :name
  validates_uniqueness_of :name, message: 'of faculty sponsor already present in database'

  has_many :study_metadata, class_name: 'Study::Metadata'
  has_many :studies, through: :study_metadata

  def count_studies
    studies.count
  end

  module Associations
    def self.included(base)
      base.validates_presence_of :faculty_sponsor
      base.belongs_to :faculty_sponsor
    end
  end
end
