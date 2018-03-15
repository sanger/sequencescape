# frozen_string_literal: true

# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012,2013,2014,2015 Genome Research Ltd.

class Transfer < ApplicationRecord
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

  belongs_to :destination, class_name: 'Asset'

  # Before creating an instance of this class the appropriate transfers need to be made from a source
  # asset to the destination one.
  before_create :create_transfer_requests

  def self.preview!(attributes)
    new(attributes) do |transfer|
      raise ActiveRecord::RecordInvalid, transfer unless transfer.valid?
      transfer.unsaved_uuid!
      transfer.send(:each_transfer) do |source, destination|
        # Needs to do nothing at all as the transfers will be recorded
      end
    end
  end

  private

  def create_transfer_requests
    # Note: submission is optional. Unlike methods, blocks don't support default argument
    # values, but any attributes not yielded will be nil. Apparently 1.9 is more consistent
    each_transfer do |source, destination, submission|
      TransferRequest.create!(
        asset: source,
        target_asset: destination,
        submission_id: submission || source.pool_id
      )
    end
  end

  # Determines if the well should not be transferred.
  def should_well_not_be_transferred?(well)
    well.nil? or well.aliquots.empty? or well.failed? or well.cancelled?
  end
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
