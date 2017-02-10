# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

class ProjectManager < ActiveRecord::Base
  extend Attributable::Association::Target

  has_many :project

  validates_presence_of :name
  validates_uniqueness_of :name, message: 'of project manager already present in database'

  module Associations
    def self.included(base)
      base.validates_presence_of :project_manager_id
      base.belongs_to :project_manager
    end
  end
end
