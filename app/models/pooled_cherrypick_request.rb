#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class PooledCherrypickRequest < Request

  # Returns a list of attributes that must match for any given pool.
  # We don't want to place any restrictions on Cherrypicking (Yet).
  def shared_attributes
    ""
  end

end
