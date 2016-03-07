#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011 Genome Research Ltd.
module ModelExtensions::Study
  def self.included(base)
    base.class_eval do
      scope :include_samples, -> { includes(:samples) }
      scope :include_projects, -> { includes(:projects) }
    end
  end
end
