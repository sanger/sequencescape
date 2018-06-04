
class WorkingDilutionPlate < DilutionPlate
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
