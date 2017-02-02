# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015,2016 Genome Research Ltd.

# This class doesn't inherit from either library creation class because most of the behaviour is unwanted.
# For example, we don't know the read length etc. when the request is created
class ExternalLibraryCreationRequest < SystemRequest
  redefine_aasm column: :state, whiny_persistence: true do
    # We have a vastly simplified two state state machine. Requests are passed once the manifest is processed
    state :pending, initial: true
    state :passed, enter: :on_passed

    event :_manifest_processed do
      transitions to: :passed, from: :pending
    end
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

  def perform_transfer_of_contents
    target_asset.aliquots << asset.aliquots.map(&:dup)
    target_asset.save!
  end
  private :perform_transfer_of_contents
end
