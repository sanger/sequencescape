# frozen_string_literal: true

# This file contains helper methods for working with the Integration Hub (Sapio) in RSpec tests.
module SapioHelper
  # Creates a study that is mastered in Sapio, bypassing the validation
  #
  # @param attributes [Hash] Additional attributes to set on the study.
  # @return [Study] The created study.
  def create_sapio_study(**attributes)
    study = build(:study, mastered_in_sapio: true, **attributes)
    study.bypass_sapio_validation = true
    study.save!
    study.bypass_sapio_validation = nil
    study
  end
end
