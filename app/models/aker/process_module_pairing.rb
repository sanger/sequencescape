module Aker
  class ProcessModulePairing < ApplicationRecord
    belongs_to :process, class_name: 'Process', foreign_key: :aker_process_id, required: true
    belongs_to :from_step, class_name: 'ProcessModule'
    belongs_to :to_step, class_name: 'ProcessModule'

    validate :from_step_or_to_step_present?

    def as_json(_options = {})
      {
        id: id,
        from_step: from_step.name,
        to_step: to_step.name,
        default_path: default_path
      }
    end

    def from_step
      super || NullProcessModule.new
    end

    def to_step
      super || NullProcessModule.new
    end

    private

    def from_step_or_to_step_present?
      return unless from_step.null? && to_step.null?
      errors.add(:process, 'must have a from step or to step')
    end
  end
end
