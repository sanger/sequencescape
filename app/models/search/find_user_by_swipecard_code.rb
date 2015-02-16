#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class Search::FindUserBySwipecardCode < Search
  def scope(criteria)
    User.with_swipecard_code(criteria['swipecard_code'])
  end
end
