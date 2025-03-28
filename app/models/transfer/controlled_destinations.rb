# frozen_string_literal: true

# The transfer from the source is controlled by some mechanism other than user choice.  Essentially
# an algorithmic transfer, which is recorded so we know what happened.
module Transfer::ControlledDestinations
  def self.included(base)
    base.class_eval do
      # Ensure that the transfers are recorded so we can see what happened.
      serialize :transfers_hash, coder: YAML
      alias_attribute :transfers, :transfers_hash
      validates_unassigned :transfers_hash
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
