# frozen_string_literal: true

# Every request "moving" an asset from somewhere to somewhere else without really transforming it
# (chemically) as, cherrypicking, pooling, spreading on the floor etc
#
# @note The setting of submission_id and outer_request is quite complicated, and depends
# on the exact route by which the transfer request has been created. The preferred route
# is by setting outer_request explicitly. However much of the historic code handles it
# via submission_id, either set explicitly, (eg Transfer::BetweenPlates#calculate_location_submissions)
# or extracted from the pool_id attribute on well, which itself is populated as part of an
# sql query. (See #with_pool_id on the well association in {Plate})
class TransferRequest < ApplicationRecord # rubocop:todo Metrics/ClassLength
  include Uuid::Uuidable
  include AASM
  include AASM::Extensions
  extend Request::Statemachine::ClassMethods

  # Determines if we attempt to filter out {Aliquot#equivalent? equivalent} aliquots
  # before performing transfers.
  attr_accessor :merge_equivalent_aliquots
  attr_writer :aliquot_attributes

  # States which are still considered to be processable (ie. not failed or cancelled)
  ACTIVE_STATES = %w[pending started passed qc_complete].freeze

  # target_asset and asset are both Receptacle objects, and are the source and target of the transfer request.
  # That is, when a transfer is made, the asset is moved from the source to the target, which are both receptacles.
  # The assets on a request can be treated as a particular class when being used by certain pieces of code.
  #  For instance, QC might be performed on a source asset that is a well, in which case we'd like to load it as such.
  belongs_to :target_asset, class_name: 'Receptacle', inverse_of: :transfer_requests_as_source, optional: false

  # inverse_of: :transfer_requests_as_target is an option that sets up a two-way association between TransferRequest
  # and Receptacle. This means that not only does a TransferRequest have an asset method that returns the associated
  # Receptacle, but a Receptacle also has a transfer_requests_as_target method that returns all associated
  # TransferRequest objects.
  # So, calling receptacle.transfer_requests_as_target will return all TransferRequest objects associated with that.
  belongs_to :asset, class_name: 'Receptacle', inverse_of: :transfer_requests_as_target, optional: false

  has_one :target_labware, through: :target_asset, source: :labware
  has_one :source_labware, through: :asset, source: :labware
  has_many :associated_requests, through: :asset, source: :requests_as_source
  has_many :transfer_request_collection_transfer_requests, dependent: :destroy
  has_many :transfer_request_collections,
           through: :transfer_request_collection_transfer_requests,
           inverse_of: :transfer_requests
  has_many :target_aliquots, through: :target_asset, source: :aliquots
  has_many :target_aliquot_requests, through: :target_aliquots, source: :request

  belongs_to :order
  belongs_to :submission

  scope :for_request, ->(request) { where(asset_id: request.asset_id) }
  scope :include_submission, -> { includes(submission: :uuid_object) }
  scope :include_for_request_state_change, -> { includes(:target_aliquot_requests, associated_requests: :request_type) }

  # Ensure that the source and the target assets are not the same, otherwise bad things will happen!
  validate :source_and_target_assets_are_different
  validate :outer_request_candidates_length, on: :create

  after_create(:perform_transfer_of_contents, :transfer_stock_wells)

  # state machine
  aasm column: :state, whiny_persistence: true do
    # The statemachine for transfer requests is more promiscuous than normal requests, as well
    # as being more concise as it has fewer states.
    state :pending, initial: true
    state :started
    state :processed_1
    state :processed_2
    state :processed_3
    state :processed_4
    state :failed, enter: :on_failed
    state :passed
    state :qc_complete
    state :cancelled, enter: :on_cancelled

    # State Machine events
    event :start do
      transitions to: :started, from: [:pending], after: :on_started
    end

    event :process_1 do
      transitions to: :processed_1, from: [:pending], after: :on_started
    end

    event :process_2 do
      transitions to: :processed_2, from: [:processed_1]
    end

    event :process_3 do
      transitions to: :processed_3, from: [:processed_2]
    end

    event :process_4 do
      transitions to: :processed_4, from: [:processed_3]
    end

    event :pass do
      # Jumping straight to passed moves through an implied started state.
      transitions to: :passed, from: :pending, after: :on_started
      transitions to: :passed, from: %i[started failed processed_2 processed_3 processed_4]
    end

    event :fail do
      transitions to: :failed, from: %i[pending started processed_1 processed_2 processed_3 processed_4 passed]
    end

    event :cancel do
      transitions to: :cancelled, from: %i[started processed_1 processed_2 processed_3 processed_4 passed qc_complete]
    end

    event :cancel_before_started do
      transitions to: :cancelled, from: [:pending]
    end

    event :detach do
      transitions to: :pending, from: [:pending]
    end

    # Not all transfer quests will make this transition, but this way we push the
    # decision back up to the pipeline
    event :qc do
      transitions to: :qc_complete, from: [:passed]
    end
  end

  convert_labware_to_receptacle_for :asset, :target_asset

  # validation method
  def source_and_target_assets_are_different
    return true unless asset_id.present? && asset_id == target_asset_id

    errors.add(:asset, 'cannot be the same as the target')
    errors.add(:target_asset, 'cannot be the same as the source')
    false
  end

  # Set the outer request associated with this transfer request
  # the outer request is the {Request} which is currently being processed,
  # such as a {LibraryCreationRequest}. Setting this ensures that the
  # transferred {Aliquots} are associated with the correct request, and that
  # submission_id on transfer request is recorded correctly.
  # @note This is particularly important when transferring out of the initial
  # {Receptacle} when there may be multiple active {Receptacle#requests_as_source}
  # @param request [Request] The request which is being processed
  def outer_request=(request)
    @outer_request = request
    self.submission_id = request.submission_id
  end

  # Sets the {#outer_request} from just a request_id
  # @param request_id [Integer] the primary key of the {Request outer request}
  def outer_request_id=(request_id)
    self.outer_request = Request.find(request_id)
  end

  def outer_request
    asset.outer_request(submission_id)
  end

  # A sibling request is a customer request out of the same asset and in the same submission
  def sibling_requests # rubocop:todo Metrics/AbcSize
    if associated_requests.loaded?
      associated_requests.select { |r| r.submission_id == submission_id }
    elsif asset.requests.loaded?
      asset.requests.select { |r| r.submission_id == submission_id }
    else
      associated_requests.where(submission: submission_id)
    end
  end

  def outer_request_candidates_length
    # Its a simple scenario, we avoid doing anything fancy and just give the thumbs up
    return true if one_or_fewer_outer_requests?

    # @todo The code below assumes that if we've got multiple outer requests then
    #       we must be at the multiplexing stage further down the pipeline. While
    #       this seems to be true in practice, it could result in some strange behaviour
    #       if triggered in other circumstances. One example was when the PacBio Library
    #       prep pipeline had multiple requests in the same submission out of each well.
    #       In this case the source aliquots didn't have a submission id set, so we couldn't
    #       find a next request to select.
    #
    #       The code currently:
    #       - For each aliquot in the receptacle detects an 'outer request' that is the next request in
    #         the submission after the request associated with the aliquot.
    #       - Ensures that this works for all aliquots in the receptacle
    #       - Creates an error for any that don't have a next request
    #
    #       In the example above, this was failing because the aliquot wasn't associated with a request,
    #       so it made no sense to find a 'next request in the submission'. It should still have failed,
    #       as the outer_request is ambiguous, but its kind of failing by accident.
    #
    #      = Fixing this
    #
    #      Firstly, I *think* this code is currently doing the right things, for the wrong reasons. So I
    #      believe it falls under general maintenance, rather than a bug fix. But all that could change.
    #
    #      This should probably be addressed as part of #3100 (https://github.com/sanger/sequencescape/issues/3100)
    #      The main aim here should probably to aim for explicitness and simplicity, rather than making
    #      this code more complicated to handle further cases.
    #
    # If we're a bit more complicated attempt to match up requests
    # This operation is a bit expensive, but needs to handle scenarios where:
    # 1) We've already done some pooling, and have multiple requests in and out
    # 2) We've got multiple aliquots from a single request, such as in Chromium
    # Failing silently at this point could result in aliquots being assigned to the wrong study
    # or the correct request information being missing downstream. (Which is then tricky to diagnose and repair)
    asset
      .aliquots
      .reduce(true) do |valid, aliquot|
        compatible = next_request_index[aliquot.id].present?
        unless compatible
          errors.add(:outer_request, "not found for aliquot #{aliquot.id} with previous request #{aliquot.request}")
        end
        valid && compatible
      end
  end

  private

  def next_request_index
    @next_request_index ||=
      asset
        .aliquots
        .each_with_object({}) do |aliquot, store|
          store[aliquot.id] = outer_request_candidates.detect do |r|
            aliquot.request&.next_requests_via_submission&.include?(r)
          end
        end
  end

  def outer_request_candidates
    @outer_request ? [@outer_request] : sibling_requests.to_a
  end

  def one_or_fewer_outer_requests?
    outer_request_candidates.length <= 1
  end

  # after_create callback method
  def perform_transfer_of_contents
    return if asset.failed? || asset.cancelled?

    target_asset.aliquots << aliquots_for_transfer
  rescue ActiveRecord::RecordNotUnique => e
    # We'll specifically handle tag clashes here so that we can produce more informative messages
    raise e unless e.message.include?('aliquot_tag_tag2_and_tag_depth_are_unique_within_receptacle')

    message = "#{asset.display_name} contains aliquots which can't be transferred due to tag clash"
    errors.add(:asset, message)

    raise Aliquot::TagClash, message
  end

  # If merge_equivalent_aliquots is false, or unset we do not detect
  # equivalent aliquots (ie. those with the same sample/tags/primer_panels etc)
  # before performing a transfer.
  # If merge_equivalent_aliquots is true, or we detect equivalent aliquots
  # and do not attempt to transfer them. Essentially this merges the two aliquots
  # together. It will NOT be possible to distinguish between them.
  # This is was added to support the Heron (Covid-19) sequencing pipeline,
  # where two plates were subject to separate PCR processes, before being
  # merged together again.
  def aliquots_for_transfer
    merge_equivalent_aliquots ? duplicates_of_distinct_source_aliquots_only : duplicates_of_all_source_aliquots
  end

  def duplicates_of_all_source_aliquots
    asset.aliquots.map { |aliquot| aliquot.dup(aliquot_attributes(aliquot)) }
  end

  def duplicates_of_distinct_source_aliquots_only
    duplicates_of_all_source_aliquots.reject do |candidate_aliquot|
      target_asset.aliquots.any? { |existing_aliquot| existing_aliquot.equivalent?(candidate_aliquot) }
    end
  end

  def transfer_stock_wells
    return unless asset.is_a?(Well) && target_asset.is_a?(Well)

    target_asset.stock_wells.attach!(asset.stock_wells_for_downstream_wells)
  end

  def aliquot_attributes(aliquot)
    outer_request_for(aliquot)&.aliquot_attributes || @aliquot_attributes || {}
  end

  def outer_request_for(aliquot)
    return outer_request_candidates.first if one_or_fewer_outer_requests?

    next_request_index[aliquot.id]
  end

  # Run on start, or if start is bypassed
  def on_started
    sibling_requests.each do |sr|
      # We only want to start the matching requests. The conditional deals with situations
      # which pre-date aliquot association with request.
      next unless target_aliquot_requests.blank? || target_aliquot_requests.ids.include?(sr.id)

      sr.start! if sr.may_start?
    end
  end

  def on_failed
    return unless target_asset
    return unless target_asset.allow_to_remove_downstream_aliquots?
    ActiveRecord::Base.transaction { target_asset.delay.remove_downstream_aliquots }
  end
  alias on_cancelled on_failed
end
