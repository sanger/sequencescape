#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011 Genome Research Ltd.
module SharedBehaviour::Named
  def self.included(base)
    base.class_eval do
      scope :with_name, ->(*names) { where(:name => names.flatten) }
      scope :sorted_by_name, -> { order('name ASC') }
    end
  end
end
