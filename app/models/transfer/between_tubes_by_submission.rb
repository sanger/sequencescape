# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2012,2013,2015 Genome Research Ltd.

class Transfer::BetweenTubesBySubmission < Transfer
  include TransfersToKnownDestination

  after_create :build_asset_links

  belongs_to :source, class_name: 'Tube'

  before_validation :ensure_destination_setup

  private

  def ensure_destination_setup
    self.destination = source.submission.multiplexed_asset
    errors.add(:destination, 'could not be found.') if destination.nil?
  end

  after_create :update_destination_tube_name
  def update_destination_tube_name
    destination.update_attributes!(name: source.name_for_child_tube)
  end

  def each_transfer
    yield(source, destination)
  end

  def request_type_between(_ignored_a, _ignored_b)
    destination.transfer_request_type_from(source)
  end

  def build_asset_links
    AssetLink::Job.create(source, [destination])
  end
end
