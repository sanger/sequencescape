# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2012,2015 Genome Research Ltd.

class TagLayout::WalkWellsOfPlate < TagLayout::Walker
  self.walking_by = 'wells of plate'

  def walk_wells
    wells_in_walking_order.each_with_index do |well, index|
      yield(well, index) unless well.nil?
    end
  end
end
