# frozen_string_literal: true
# This class doesn't inherit from either library creation class because most of the behaviour is unwanted.
# For example, we don't know the read length etc. when the request is created
class ExternalLibraryCreationRequest < SystemRequest
  redefine_aasm column: :state, whiny_persistence: true do
    # We have a vastly simplified two state state machine. Requests are passed once the manifest is processed
    state :pending, initial: true
    state :passed, enter: :on_passed
    state :failed
    state :cancelled

    event :_manifest_processed do
      transitions to: :passed, from: :pending
    end

    event :cancel do
      transitions to: :cancelled, from: :pending
    end

    event :cancel_before_started # No transitions.
  end

  def manifest_processed!
    _manifest_processed! if pending?
  end

  def on_passed
    perform_transfer_of_contents
  end

  def allow_library_update?
    pending?
  end

  private

  def perform_transfer_of_contents
    target_asset.aliquots << asset.aliquots.map(&:dup)
    target_asset.save!
  end
end
