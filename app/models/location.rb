#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2012 Genome Research Ltd.
class Location < ActiveRecord::Base
  has_many :pipelines
  #has_many :assets, :as => :holder

  def set_locations(assets)
    assets.each do |asset|
      asset.location = self
      asset.save
    end
  end
end
