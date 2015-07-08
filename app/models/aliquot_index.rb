#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.

class AliquotIndex < ActiveRecord::Base

  belongs_to :aliquot
  belongs_to :lane

  validates_presence_of :aliquot
  validates_presence_of :lane
  validates_numericality_of :aliquot_index, :only_integer => true, :greater_than => 0, :allow_blank? => false

end
