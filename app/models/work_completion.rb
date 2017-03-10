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
class WorkCompletion < ActiveRecord::Base
  include Uuid::Uuidable
  # The user who performed the state change
  belongs_to :user, required: true
  # The plate on which requests were completed
  belongs_to :target, class_name: Asset, required: true
  # The submissions which were passed. Mainly kept for auditing
  # purposes
  has_many :work_completions_submissions, dependent: :destroy
  has_many :submissions, through: :work_completions_submissions

  after_create :pass_and_attach_requests

  private

  def pass_and_attach_requests
    connect_requests
  end

  def connect_requests
    target_wells.each do |target_well|
      target_well.stock_wells.each do |source_well|
        # We may have multiple requests out of each well, however we're only concerned
        # about those associated with the active submission.
        # We've already eager loaded requests out of the stock wells, so filter in Ruby.
        upstream = source_well.requests.detect do |r|
          r.library_creation? && submission_ids.include?(r.submission_id)
        end || raise("Could not find matching upstream requests for #{target_well.map_description}")

        # We need to find the downstream requests BEFORE connecting the upstream
        # This is because submission.next_requests tries to take a shortcut through
        # the target_asset if it is defined.
        downstream = upstream.submission.next_requests(upstream)
        downstream.each { |ds| ds.update_attributes!(asset: target_well) }

        # In some cases, such as the Illumina-C pipelines, requests might be
        # connected upfront. We don't want to touch these.
        upstream.target_asset ||= target_well
        # We don't try and pass failed requests.
        # I'm not 100% convinced this decision belongs here, and instead
        # we may want to let the client specify wells to pass, and perform
        # validation to ensure this is correct. However this increases
        # the complexity of both the code and the interface, with only
        # marginal system simplification.
        upstream.pass if upstream.may_pass?
        upstream.save!
      end
    end
  end

  def target_wells
    target.wells.include_stock_wells.include_requests_as_target
  end
end
