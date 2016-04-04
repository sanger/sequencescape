#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2015 Genome Research Ltd.

module ModelExtensions::Asset
  def self.included(base)
    base.class_eval do
      scope :include_barcode_prefix, -> { includes(:barcode_prefix) }
    end
  end
end
