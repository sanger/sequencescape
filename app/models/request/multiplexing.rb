# frozen_string_literal: true
class Request::Multiplexing < CustomerRequest # rubocop:todo Style/Documentation
  # If we re request we need to make sure we look in the new
  # source wells for our repool
  after_create :flag_asset_as_stock_well, if: :asset
  def flag_asset_as_stock_well
    asset.stock_wells << asset
  end

  redefine_aasm column: :state, whiny_persistence: true do
    state :pending, initial: true
    state :started
    state :passed
    state :failed
    state :cancelled

    event :submission_cancelled, manual_only?: true do
      transitions to: :cancelled, from: %i[pending cancelled]
    end
    event :start do
      transitions to: :started, from: [:pending]
    end
    event :pass do
      transitions to: :passed, from: %i[pending started]
    end
    event :fail do
      transitions to: :failed, from: %i[pending started]
    end
    event :cancel do
      transitions to: :cancelled, from: %i[started passed]
    end

    event :cancel_before_started do
      transitions to: :cancelled, from: %i[pending hold]
    end

    # If the library creation is failed, we're not going to be pooling.
    event :fail_from_upstream, manual_only?: true do
      transitions to: :cancelled, from: [:pending]
      transitions to: :failed, from: [:started]
      transitions to: :failed, from: [:passed]
    end
  end
end
