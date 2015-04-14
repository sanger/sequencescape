#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012,2013 Genome Research Ltd.
class Search::FindIlluminaBStockPlates < Search::FindIlluminaBPlates
  def illumina_b_plate_purposes
    PlatePurpose.find_all_by_name([IlluminaB::PlatePurposes::STOCK_PLATE_PURPOSE,IlluminaHtp::PlatePurposes::STOCK_PLATE_PURPOSE].concat(Pulldown::PlatePurposes::STOCK_PLATE_PURPOSES))
  end
  private :illumina_b_plate_purposes
end
