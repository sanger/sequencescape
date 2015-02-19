#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012,2013,2014 Genome Research Ltd.
class StockMultiplexedLibraryTube < Tube
  include Asset::Stock

  def stock_wells
    purpose.stock_wells(self)
  end

  def created_with_request_options
    parent.created_with_request_options
  end

end
