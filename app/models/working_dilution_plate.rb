# frozen_string_literal: true

# A WorkingDilutionPlate is made from a parent plate (usually via a direct stamp)
# and dilutes the material within by a known factor. Concentration readings
# made on a WorkingDiltuionPlate will need to propergate back up scaled appropriately.
# RIN propagate back up unchanged.
# Volume shouldn't propagate.
class WorkingDilutionPlate < DilutionPlate
  def update_qc_values_with_parser(parser)
    ActiveRecord::Base.transaction do
      super

      # If we have multiple parents, or don't have a dilution
      # factor specified then move on.
      return true unless parents.one? && dilution_factor.present?

      multiplier = dilution_factor / (parent.dilution_factor || 1.0)
      dilution_parser = Parsers::DilutionParser.new(parser, multiplier)
      parent.update_qc_values_with_parser(dilution_parser)
    end
    true
  end
end
