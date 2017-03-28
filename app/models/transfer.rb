# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012,2013,2014,2015 Genome Research Ltd.

class Transfer < ActiveRecord::Base
  module Associations
    def self.included(base)
      base.class_eval do
        include Transfer::State

        has_many :transfers_as_source,      ->() { order('created_at ASC') }, class_name: 'Transfer', foreign_key: :source_id
        has_many :transfers_to_tubes,       ->() { order('created_at ASC') }, class_name: 'Transfer::BetweenPlateAndTubes', foreign_key: :source_id
        has_many :transfers_as_destination, ->() { order('id ASC') },         class_name: 'Transfer', foreign_key: :destination_id

        # This looks odd but it's a LEFT OUTER JOIN, meaning that the rows we would be interested in have no source_id.
        scope :with_no_outgoing_transfers, -> {
          select("DISTINCT #{base.quoted_table_name}.*")
            .joins("LEFT OUTER JOIN `transfers` outgoing_transfers ON outgoing_transfers.`source_id`=#{base.quoted_table_name}.`id`")
            .where('outgoing_transfers.source_id IS NULL')
        }

        scope :including_used_plates?, ->(filter) {
          filter ? where('true') : with_no_outgoing_transfers
        }
      end
    end
  end

  module State
    # These are all of the valid states but keep them in a priority order: in other words, 'started' is more important
    # than 'pending' when there are multiple requests (like a plate where half the wells have been started, the others
    # are failed).
    ALL_STATES = %w(started qc_complete pending passed failed cancelled)

    def self.state_helper(names)
      Array(names).each do |name|
        module_eval("def #{name}? ; state == #{name.to_s.inspect} ; end")
      end
    end

    state_helper(ALL_STATES)

    # The state of an asset is based on the transfer requests for the asset.  If they are all in the same
    # state then it takes that state.  Otherwise we take the "most optimum"!
    def state
      state_from(transfer_requests)
    end

    def state_from(state_requests)
      unique_states = state_requests.map(&:state).uniq
      return unique_states.first if unique_states.size == 1
      ALL_STATES.detect { |s| unique_states.include?(s) } || default_state || 'unknown'
    end

    module PlateState
      def self.included(base)
        base.class_eval do
         scope :in_state, ->(states) {
            states = Array(states).map(&:to_s)

            # If all of the states are present there is no point in actually adding this set of conditions because we're
            # basically looking for all of the plates.
            if states.sort != ALL_STATES.sort
              # NOTE: The use of STRAIGHT_JOIN here forces the most optimum query on MySQL, where it is better to reduce
              # assets to the plates, then look for the wells, rather than vice-versa.  The former query takes fractions
              # of a second, the latter over 60.
              query_conditions, join_options = 'transfer_requests_as_target.state IN (?)', [
                'STRAIGHT_JOIN `container_associations` ON (`assets`.`id` = `container_associations`.`container_id`)',
                "INNER JOIN `assets` wells_assets ON (`wells_assets`.`id` = `container_associations`.`content_id`) AND (`wells_assets`.`sti_type` = 'Well')",
                "LEFT OUTER JOIN `requests` transfer_requests_as_target ON transfer_requests_as_target.target_asset_id = wells_assets.id AND (transfer_requests_as_target.`sti_type` IN (#{[TransferRequest, *TransferRequest.descendants].map(&:name).map(&:inspect).join(',')}))"
              ]

              # Note that 'state IS NULL' is included here for plates that are stock plates, because they will not have any
              # transfer requests coming into their wells and so we can assume they are pending (from the perspective of
              # pulldown at least).
              query_conditions = 'transfer_requests_as_target.state IN (?)'
              if states.include?('pending')
                join_options << 'INNER JOIN `plate_purposes` ON (`plate_purposes`.`id` = `assets`.`plate_purpose_id`)'
                query_conditions << ' OR (transfer_requests_as_target.state IS NULL AND plate_purposes.stock_plate=TRUE)'
              end

              joins(join_options).where([query_conditions, states])
            else
              {}
            end
                          }
        end
      end
    end

    module TubeState
      def self.included(base)
        base.class_eval do
         scope :in_state, ->(states) {
            states = Array(states).map(&:to_s)

            # If all of the states are present there is no point in actually adding this set of conditions because we're
            # basically looking for all of the plates.
            if states.sort != ALL_STATES.sort

              join_options = [
                "LEFT OUTER JOIN `requests` transfer_requests_as_target ON transfer_requests_as_target.target_asset_id = `assets`.id AND (transfer_requests_as_target.`sti_type` IN (#{[TransferRequest, *TransferRequest.descendants].map(&:name).map(&:inspect).join(',')}))"
              ]

              joins(join_options).where(transfer_requests_as_target: { state: states })
            else
              all
            end
                          }
         scope :without_finished_tubes, ->(purpose) {
            where.not(["assets.plate_purpose_id IN (?) AND transfer_requests_as_target.state = 'passed'", purpose.map(&:id)])
                                        }
        end
      end
    end
  end

  # The transfers are described in some manner, like direct transfers of one well to the same well on
  # another plate.
  module TransfersBySchema
    def self.included(base)
      base.class_eval do
        serialize :transfers
        validates :transfers, presence: true, allow_blank: false
      end
    end
  end

  # The transfer goes from the source to a specified destination and this can only happen once.
  module TransfersToKnownDestination
    def self.included(base)
      base.class_eval do
        belongs_to :destination, polymorphic: true
        validates_presence_of :destination
        validates_uniqueness_of :destination_id, scope: [:destination_type, :source_id], message: 'can only be transferred to once from the source'
      end
    end
  end

  # The transfer from the source is controlled by some mechanism other than user choice.  Essentially
  # an algorithmic transfer, which is recorded so we know what happened.
  module ControlledDestinations
    def self.included(base)
      base.class_eval do
        # Ensure that the transfers are recorded so we can see what happened.
        serialize :transfers
        validates_unassigned :transfers
      end
    end

    def each_transfer
      well_to_destination.each do |source, destination_and_additional_information|
        destination, *extra_information = Array(destination_and_additional_information)
        yield(source, destination)
        record_transfer(source, destination, *extra_information)
      end
    end
    private :each_transfer
  end

  include Uuid::Uuidable

  self.inheritance_column = 'sti_type'

  # So we can track who is requesting the transfer
  belongs_to :user
  validates_presence_of :user

  # The source plate and the destination asset (which varies between different types of transfers)
  # You can only transfer from one plate to another once, anything else is an error.
  belongs_to :source, class_name: 'Plate'
  validates_presence_of :source
  scope :include_source, -> { includes(source: ModelExtensions::Plate::PLATE_INCLUDES) }

  # Before creating an instance of this class the appropriate transfers need to be made from a source
  # asset to the destination one.
  before_create :create_transfer_requests
  def create_transfer_requests
    # Note: submission is optional. Unlike methods, blocks don't support default argument
    # values, but any attributes not yielded will be nil. Apparently 1.9 is more consistent
    each_transfer do |source, destination, submission|
      request_type_between(source, destination).create!(
        asset: source,
        target_asset: destination,
        submission_id: submission || source.pool_id
      )
    end
  end
  private :create_transfer_requests

  def self.preview!(attributes)
    new(attributes) do |transfer|
      raise ActiveRecord::RecordInvalid, transfer unless transfer.valid?
      transfer.unsaved_uuid!
      transfer.send(:each_transfer) do |source, destination|
        # Needs to do nothing at all as the transfers will be recorded
      end
    end
  end

  # Determines if the well should not be transferred.
  def should_well_not_be_transferred?(well)
    well.nil? or well.aliquots.empty? or well.failed? or well.cancelled?
  end
  private :should_well_not_be_transferred?
end

require_dependency 'transfer/between_plate_and_tubes'
require_dependency 'transfer/between_plates'
require_dependency 'transfer/between_plates_by_submission'
require_dependency 'transfer/between_specific_tubes'
require_dependency 'transfer/between_tubes_by_submission'
require_dependency 'transfer/from_plate_to_specific_tubes'
require_dependency 'transfer/from_plate_to_specific_tubes_by_pool'
require_dependency 'transfer/from_plate_to_tube'
require_dependency 'transfer/from_plate_to_tube_by_multiplex'
require_dependency 'transfer/from_plate_to_tube_by_submission'
