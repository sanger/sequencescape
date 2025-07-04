# frozen_string_literal: true
# A pick list is a lightweight wrapper to provide a simplified interface
# for automatically generating {Batch batches} for the {CherrypickPipeline}.
# It is intended to isolate external applications from the implementation
# and to provide an interface for eventually building a simplified means
# for generating cherrypicks
class PickList < ApplicationRecord
  REQUEST_TYPE_KEY = 'cherrypick'

  after_create :process

  # PickLists are currently a wrapper for submissions, and batches. In future
  # it would be nice if we could make them more lightweight, and the cherrypicking
  # interface would use them directly.
  belongs_to :submission, optional: false, autosave: true
  has_many :batches, -> { distinct }, through: :submission

  enum :state, { pending: 0, built: 1 }

  delegate :orders, to: :submission

  # Asynchronous indicates whether the submission should be built asynchronously
  # via the delayed job, or synchronously.
  attribute :asynchronous, :boolean, default: true

  #
  # Build a list of picks based on the supplied array of pick-attributes
  #
  # @param [Hash] picks Array of hashes with the following parameters
  #               source_receptacle: The source {Receptacle}
  #               study: The {Study} associated with the pick
  #               project: The {Project} to charge for the pick
  #
  #               study and project are not required is already set on the {Aliquot aliquots} in the source_receptacle
  #
  # @return [Array<PickList::Pick>] The picks created
  #
  def pick_attributes=(picks)
    picks
      .map { |pick| Pick.new(pick) }
      .group_by(&:order_options)
      .each { |order_options, pick_group| orders << build_order(pick_group, order_options) }
  end

  def pick_attributes
    orders.flat_map do |order|
      order.assets.map do |source_receptacle|
        { source_receptacle: source_receptacle, study: order.study, project: order.project }
      end
    end
  end

  # We can't use a has-many through, as we end up modifying the association
  # and the setter above won't automatically update the getter that
  # has_many would define.
  # TODO: Some performance improvements here, but will revisit once the API stabilizes
  #       as I'm tempted to use 'picks' instead.
  def receptacles
    orders.flat_map(&:assets)
  end

  def links
    [{ name: "Pick-list #{id}", url: url_helpers.pick_list_url(self, host: configatron.site_url) }] +
      batches.map do |batch|
        { name: "Batch #{batch.id}", url: url_helpers.batch_url(batch, host: configatron.site_url) }
      end
  end

  def process_immediately
    submission.process_synchronously!
    create_batch!
    update!(state: :built)
  end

  private

  # Trigger the creation of the requests and batch.
  # The asynchronous attribute indicates if this happens in the background,
  # via a delayed job, or synchronously.
  def process
    asynchronous ? queue_processing : process_immediately
  end

  # Add a delayed job to the queue which will trigger the process_immediately
  # method
  def queue_processing
    Delayed::Job.enqueue PickListJob.new(id)
  end

  # Returns the submission associated with the pick-list.
  # Its listed as a private method, as it is intended as an implementation
  # detail, and I'm hoping that we'll be able to remove the need for it.
  def submission
    super || build_submission(user:)
  end

  def request_type
    @request_type ||= RequestType.find_by!(key: REQUEST_TYPE_KEY)
  end

  def build_order(pick_group, order_options)
    AutomatedOrder.new(
      user: user,
      assets: pick_group.map(&:source_receptacle),
      request_types: [request_type_id],
      **order_options # Merge the order options into the arguments
    )
  end

  def create_batch!
    batch = Batch.create!(requests: submission.requests.reload, pipeline: pipeline, user: user)

    # If the pipeline requires a position, we set the position based on the asset barcode.
    batch.set_position_based_on_asset_barcode if batch.requires_position?
  end

  def user
    User.sequencescape
  end

  def pipeline
    request_type.pipelines.last!
  end

  def request_type_id
    request_type.id
  end

  def url_helpers
    Rails.application.routes.url_helpers
  end
end
