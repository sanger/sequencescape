# frozen_string_literal: true

# The transfer goes from the source to a specified destination and this can only happen once.
module Transfer::TransfersToKnownDestination
  def self.included(base)
    base.class_eval do
      belongs_to :destination, polymorphic: true
      validates :destination, presence: true
      validates :destination_id, uniqueness: { scope: [:destination_type, :source_id], message: 'can only be transferred to once from the source' }
    end
  end
end
