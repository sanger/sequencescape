# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2013,2014,2015 Genome Research Ltd.

class BulkTransfer < ActiveRecord::Base
  include Uuid::Uuidable

  has_many :transfers

  belongs_to :user
  validates_presence_of :user

  after_create :build_transfers!

  attr_accessor :well_transfers

  def build_transfers!
    ActiveRecord::Base.transaction do
      each_transfer do |source, destination, transfers|
        Transfer::BetweenPlates.create!(
          source: source,
          destination: destination,
          user: user,
          transfers: transfers,
          bulk_transfer_id: id
        )
      end
    end
  end
  private :build_transfers!

  def each_transfer
    well_transfers.group_by { |tf| [tf['source_uuid'], tf['destination_uuid']] }.each do |source_dest, all_transfers|
      transfers = Hash.new { |h, i| h[i] = [] }
      all_transfers.each { |t| transfers[t['source_location']] << t['destination_location'] }

      source = Uuid.find_by(external_id: source_dest.first).resource
      destination = Uuid.find_by(external_id: source_dest.last).resource
      errors.add(:source, 'is not a plate') unless source.is_a?(Plate)
      errors.add(:destination, 'is not a plate') unless destination.is_a?(Plate)
      raise ActiveRecord::RecordInvalid, self if errors.count > 0
      yield(source, destination, transfers)
    end
  end
  private :each_transfer
end
