# frozen_string_literal: true
class Transfer::BetweenSpecificTubes < Transfer # rubocop:todo Style/Documentation
  include TransfersToKnownDestination

  belongs_to :source, class_name: 'Tube'

  after_create :update_destination_tube_name
  def update_destination_tube_name
    destination.update!(name: source.name_for_child_tube)
  end
  private :update_destination_tube_name

  def each_transfer
    yield(source, destination)
  end
  private :each_transfer
end
