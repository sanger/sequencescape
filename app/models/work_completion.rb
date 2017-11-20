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
  # The user who performed the state change
  belongs_to :user, required: true
  # The plate on which requests were completed
  belongs_to :target, class_name: 'Asset', required: true
  # The submissions which were passed. Mainly kept for auditing
  # purposes
  has_many :work_completions_submissions, dependent: :destroy
  # Submissions should already be valid at this point.
  # We don't re-validate for performance reasons.
  has_many :submissions, through: :work_completions_submissions, validate: false

  after_create :pass_and_attach_requests

  private

  def pass_and_attach_requests
    connect_requests
    update_stock_wells
  end

  def connect_requests
    target_wells.each do |target_well|
      next if target_well.stock_wells.empty?
      # Upstream requests our on our stock wells.
      detect_upstream_requests(target_well).each do |upstream|
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

  def detect_upstream_requests(target_well)
    upstream_requests = target_well.stock_wells.each_with_object([]) do |source_well, found_upstream_requests|
      # We may have multiple requests out of each well, however we're only concerned
      # about those associated with the active submission.
      # We've already eager loaded requests out of the stock wells, so filter in Ruby.
      source_well.requests_as_source.each do |r|
        found_upstream_requests << r if suitable_request?(r)
      end
    end
    # We've looked at all the requests, on all the stock wells and still haven't found
    # what we're looking for.
    raise("Could not find matching upstream requests for #{target_well.map_description}") if upstream_requests.empty?
    upstream_requests
  end

  def suitable_request?(request)
    request.library_creation? && submission_ids.include?(request.submission_id)
  end

  def update_stock_wells
    Well::Link.stock.where(target_well_id: target_wells.map(&:id)).delete_all
    Well::Link.stock.import(target_wells.map { |well| { source_well_id: well.id, target_well_id: well.id } })
    # target_wells.each do |target_well|
    #   target_well.stock_wells = [target_well]
    # end
  end

  def target_wells
    @target_wells ||= target.wells
                            .includes(:aliquots)
                            .include_stock_wells_for_modification
                            .include_requests_as_target
                            .where(requests: { submission_id: submissions })
  end
end
