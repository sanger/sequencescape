#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
module ModelExtensions::TagLayout
  def self.included(base)
    base.class_eval do
      extend ModelExtensions::Plate::NamedScopeHelpers
      include_plate_named_scope :plate

      scope :include_tag_group, -> { includes(:tag_group => :tags) }
    end
  end
end
