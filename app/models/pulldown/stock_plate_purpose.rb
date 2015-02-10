#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011,2012 Genome Research Ltd.
# Specialised implementation of the plate purpose for the stock plates that lead into the various
# pulldown pipelines.
class Pulldown::StockPlatePurpose < PlatePurpose
  include PlatePurpose::Stock
end
