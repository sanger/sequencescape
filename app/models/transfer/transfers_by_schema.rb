# frozen_string_literal: true

# The transfers are described in some manner, like direct transfers of one well to the same well on
# another plate.
module Transfer::TransfersBySchema
  def self.included(base)
    base.class_eval do
      serialize :transfers_hash, coder: YAML
      alias_attribute :transfers, :transfers_hash
      validates :transfers_hash, presence: true, allow_blank: false
    end
  end
end
