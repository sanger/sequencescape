# frozen_string_literal: true
# A WorkCompletion can be used to pass library creation
# requests. It will also link the requests onto the correct
# wells of the target plate. It takes the following:
# target: The plate on which the library has been completed.
# user: the user performing tha action
# submissions: an array of submissions which will be passed.
# Requirements:
# The wells of the target plate are expected to have stock
# well_links to the plate on which the orignal library_creation
# requests were made. This provides a means of finding the library
# creation requests.
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

  # The plate on which requests were completed
  belongs_to :target, class_name: 'Labware', optional: false

  # The submissions which were passed. Mainly kept for auditing
  # purposes
  has_many :work_completions_submissions, dependent: :destroy

  # Submissions should already be valid at this point.
  # We don't re-validate for performance reasons.
  has_many :submissions, through: :work_completions_submissions, validate: false

  after_create :pass_and_attach_requests

  private

  def pass_and_attach_requests
    if target.respond_to?(:wells)
      PlateCompletion.new(target, submission_ids).process
    else
      TubeCompletion.new(target, submission_ids).process
    end
  end
end
