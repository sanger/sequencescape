#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class Search::FindIlluminaAStockPlates < Search::FindIlluminaAPlates
  def illumina_a_plate_purposes
    PlatePurpose.find_all_by_name(IlluminaHtp::PlatePurposes::STOCK_PLATE_PURPOSE)
  end
  private :illumina_a_plate_purposes
end
