#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
class Search::FindPulldownStockPlates < Search::FindPulldownPlates
  def pulldown_plate_purposes
    PlatePurpose.find_all_by_name(Pulldown::PlatePurposes::STOCK_PLATE_PURPOSES)
  end
  private :pulldown_plate_purposes
end
