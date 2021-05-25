# frozen_string_literal: true

# The transfer goes from the source to a specified destination and this can only happen once.
module Transfer::TransfersToKnownDestination
  def self.included(base)
    base.class_eval do
      belongs_to :destination, class_name: 'Labware'
      validates :destination, presence: true
      validates :destination_id,
                uniqueness: {
                  scope: :source_id,
                  message: 'can only be transferred to once from the source'
                }
    end
  end
end
