# frozen_string_literal: true
##
# Extended validators are used to provide extra validation
# of submission. They are associated with request types
# and will import validation behaviour into submission.
#
# behaviour => the module that will be included in the validator, must respond to validate(submission)
# options   => serialized hash for configuration

class ExtendedValidator < ApplicationRecord
  class RequestTypeExtendedValidator < ApplicationRecord
    self.table_name = ('request_types_extended_validators')

    belongs_to :extended_validator
    belongs_to :request_type
    validates :extended_validator, presence: true
    validates :request_type, presence: true
  end

  after_initialize :import_behaviour

  def import_behaviour
    return if behaviour.nil?

    behavior_module = "ExtendedValidator::#{behaviour}".constantize
    class_eval { include(behavior_module) }
  end

  has_many :request_type_extened_validators,
           dependent: :destroy,
           class_name: 'ExtendedValidator::RequestTypeExtendedValidator'
  has_many :request_types, through: :request_type_extened_validators

  validates :behaviour, presence: true
  serialize :options, coder: YAML

  scope :for_submission,
        ->(submission) do
          joins(
            # rubocop:todo Layout/LineLength
            'INNER JOIN request_types_extended_validators ON request_types_extended_validators.extended_validator_id = extended_validators.id'
            # rubocop:enable Layout/LineLength
          ).where(request_types_extended_validators: { request_type_id: submission.request_types })
        end
end
