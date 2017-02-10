# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015,2016 Genome Research Ltd.

class PicoDilutionPlate < DilutionPlate
  # self.per_page is set to a "highish" number so that the first page
  # sent to PicoGreen is likely to hold all the rececent PicoDilutionPlates
  self.per_page = 5000
  self.prefix = 'PD'

  def self.index_to_hash(pico_dilutions)
    pico_dilutions.map { |pico_dilution| pico_dilution.to_pico_hash }
  end
end
