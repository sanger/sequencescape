#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014,2015 Genome Research Ltd.

Plate.requiring_fluidigm_data.find_each do |plate|
  plate.retrieve_fluidigm_data
end
