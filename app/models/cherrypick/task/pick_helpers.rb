# frozen_string_literal: true
module Cherrypick::Task::PickHelpers
  def self.included(base)
    base.class_eval do
      include Cherrypick::Task::PickByNanoGramsPerMicroLitre
      include Cherrypick::Task::PickByNanoGrams
      include Cherrypick::Task::PickByMicroLitre
      include Cherrypick::Task::BufferVolumeForEmptyWellsOption
    end
  end

  def valid_float_param?(input_value)
    input_value.present? && (input_value.to_f > 0.0)
  end
  private :valid_float_param?
end
