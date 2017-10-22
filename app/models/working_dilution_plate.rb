# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

class WorkingDilutionPlate < DilutionPlate
  self.prefix = 'WD'

  def update_qc_values_with_parser(parser, scale: nil)
    ActiveRecord::Base.transaction do
      super
      # If we have multiple parents, or don't have a dilution
      # factor specified then move on.
      return true unless parents.one? && dilution_factor.present?
      multiplier = dilution_factor / (parent.dilution_factor || 1.0)
      scales = [
        [:set_rin, 1],
        [:set_concentration, multiplier]
      ]
      parent.update_qc_values_with_parser(parser, scale: scales)
    end
    true
  end
end
