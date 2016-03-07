#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.

# This class doesn't inherit from either library creation class because most of the behaviour is unwanted.
# For example, we don't know the read length etc. when the request is created
class ExternalLibraryCreationRequest < SystemRequest

  redefine_state_machine do
    # We have a vastly simplified two state state machine. Requests are passed once the manifest is processed
    aasm_column :state
    aasm_state :pending
    aasm_state :passed, :enter => :on_passed
    aasm_initial_state :pending

    aasm_event :manifest_processed do
      transitions :to => :passed, :from => [:pending]
    end
  end

  def on_passed
    perform_transfer_of_contents
  end

  def perform_transfer_of_contents
    target_asset.aliquots << asset.aliquots.map(&:dup)
    target_asset.save!
  end
  private :perform_transfer_of_contents
end
