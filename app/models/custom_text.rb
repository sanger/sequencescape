#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012 Genome Research Ltd.
class CustomText < ActiveRecord::Base
  after_save :clear_text_cache!

  # If the value of this CustomText instance was saved in cache
  # e.g. the appication wide information box, delete it.
  def clear_text_cache!
    Rails.cache.delete(name)
  end

  def name
    "#{identifier}-#{differential}"
  end
end
