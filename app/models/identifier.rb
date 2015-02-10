#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011 Genome Research Ltd.
class Identifier < ActiveRecord::Base
  validates_presence_of :resource_name, :identifiable_id
  validates_uniqueness_of :external_id, :scope => [:identifiable_id, :resource_name] # only one external per asset per resource

  belongs_to :identifiable, :polymorphic => true
  belongs_to :external, :polymorphic => true
end
