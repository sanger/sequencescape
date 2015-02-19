#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class Transfer::BetweenSpecificTubes < Transfer
  include TransfersToKnownDestination

  belongs_to :source, :polymorphic => true

  after_create :update_destination_tube_name
  def update_destination_tube_name
    destination.update_attributes!(:name => source.name_for_child_tube)
  end
  private :update_destination_tube_name

  def each_transfer(&block)
    yield(source, destination)
  end
  private :each_transfer

  def request_type_between(ignored_a, ignored_b)
    destination.transfer_request_type_from(source)
  end
  private :request_type_between
end
