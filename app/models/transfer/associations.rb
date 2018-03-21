# frozen_string_literal: true

# Include in assets that can act as sources/destinations for transfers
module Transfer::Associations
  def self.included(base)
    base.class_eval do
      include Transfer::State

      has_many :transfers_as_source,
               -> { order(created_at: :asc) },
               class_name: 'Transfer',
               foreign_key: :source_id,
               inverse_of: :source

      has_many :transfers_to_tubes,
               -> { order(created_at: :asc) },
               class_name: 'Transfer::BetweenPlateAndTubes',
               foreign_key: :source_id,
               inverse_of: :source

      has_many :transfers_as_destination,
               -> { order(id: :asc) },
               class_name: 'Transfer',
               foreign_key: :destination_id,
               inverse_of: :destination

      # This looks odd but it's a LEFT OUTER JOIN, meaning that the rows we would be interested in have no source_id.
      scope :with_no_outgoing_transfers, lambda {
        select("DISTINCT #{base.quoted_table_name}.*")
          .joins("LEFT OUTER JOIN `transfers` outgoing_transfers ON outgoing_transfers.`source_id`=#{base.quoted_table_name}.`id`")
          .where('outgoing_transfers.source_id IS NULL')
      }
    end
  end
end
