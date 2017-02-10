# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2013,2015 Genome Research Ltd.

class Transfer::BetweenSpecificTubes < Transfer
  include TransfersToKnownDestination

  belongs_to :source, class_name: 'Tube'

  after_create :update_destination_tube_name
  def update_destination_tube_name
    destination.update_attributes!(name: source.name_for_child_tube)
  end
  private :update_destination_tube_name

  def each_transfer
    yield(source, destination)
  end
  private :each_transfer

  def request_type_between(_ignored_a, _ignored_b)
    destination.transfer_request_type_from(source)
  end
  private :request_type_between
end
