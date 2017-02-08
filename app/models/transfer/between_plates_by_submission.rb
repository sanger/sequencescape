# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012,2015 Genome Research Ltd.

# This is effectively pooling: all wells that have come from the same submission will be transferred
# into the same well on the destination plate.
class Transfer::BetweenPlatesBySubmission < Transfer
  extend ::ModelExtensions::Plate::NamedScopeHelpers
  include_plate_named_scope :source
  include_plate_named_scope :destination

  include TransfersToKnownDestination
  include ControlledDestinations
  include BuildsStockWellLinks

  include Asset::Ownership::ChangesOwner
  set_target_for_owner(:destination)

  #--
  # Track back from the specified well to the stock plate well that has been transfered here.  Then
  # find the non-transfer request where the stock well was the source asset, and from there the submission
  # that it came from.  Hence all stock wells that are part of the same submission will be transferred to
  # the same well.
  #++
  def well_to_destination
    {}.tap do |sources_to_target|
      # Group the wells based on the submission
      groups = source.wells.in_column_major_order.with_pool_id.group_by(&:pool_id).delete_if { |k, _| k.nil? }.values

      # Submission group 1 will go into A1, group 2 into B1, group 3 C1, etc.
      Map.walk_plate_in_column_major_order(source.size) do |position, index|
        next unless index < groups.size
        destination_well = destination.wells.located_at(position.description).first or
          raise StandardError, "The destination does not have a well at #{position.description}"
        groups[index].each do |source|
          sources_to_target[source] = destination_well unless should_well_not_be_transferred?(source)
        end
      end
    end
  end
  private :well_to_destination

  def record_transfer(source, destination)
    self.transfers ||= {}
    self.transfers[source.map.description] = destination.map.description
  end
  private :record_transfer

  # Request type for transfers is based on the plates, not the wells we're transferring
  def request_type_between(_ignored_a, _ignored_b)
    destination.transfer_request_type_from(source)
  end
  private :request_type_between
end
