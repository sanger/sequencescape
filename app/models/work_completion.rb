# frozen_string_literal: true

# A WorkCompletion can be used to pass library creation
# requests. It will also link the upstream and downstream requests to the correct receptacles.
# It takes the following:
#
# target: The labware on which the library has been completed.
#
# user: the user performing the action
#
# submissions: an array of submissions which will be passed (although this
# is done through the request ids on the aliquots, not directly through the submissions).
#
class WorkCompletion < ApplicationRecord
  include Uuid::Uuidable

  # These includes are required for library passing
  REQUEST_INCLUDES = [
    { submission: :orders },
    { request_type: :request_type_validators },
    { target_asset: :aliquots },
    :order,
    :request_events,
    :request_metadata
  ].freeze

  # The user who performed the state change
  belongs_to :user, optional: false

  # The labware on which requests were completed
  belongs_to :target, class_name: 'Labware', optional: false

  # The submissions which were passed. Mainly kept for auditing
  # purposes
  has_many :work_completions_submissions, dependent: :destroy

  # Submissions should already be valid at this point.
  # We don't re-validate for performance reasons.
  has_many :submissions, through: :work_completions_submissions, validate: false

  after_create :pass_and_attach_requests

  private

  # @!method pass_and_attach_requests
  #   Determines the appropriate processing class based on the target labware type
  #   and invokes its `process` method to handle request passing and linking.
  #
  #   @return [void]
  #
  #   @example
  #     pass_and_attach_requests
  #
  #   The method selects the processing class as follows:
  #   - If the target labware responds to `racked_tubes`, it uses `TubeRackCompletion`.
  #   - If the target labware responds to `wells`, it uses `PlateCompletion`.
  #   - Otherwise, it defaults to `TubeCompletion`.
  def pass_and_attach_requests
    processing_class =
      if target.respond_to?(:wells)
        PlateCompletion
      elsif target.respond_to?(:racked_tubes)
        TubeRackCompletion
      else
        TubeCompletion
      end
    processing_class.new(target, submission_ids, self).process
  end
end
