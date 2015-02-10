#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
class Request::Multiplexing < Request

  after_create :register_transfer_callback

  def register_transfer_callback
    # We go via order as we need to get a particular instance of submission
    order.submission.register_callback(:once) do
      Transfer::FromPlateToTubeByMultiplex.create!(
        :source => self.asset.plate,
        :user   => self.order.user
      )
    end
  end


  redefine_state_machine do
      aasm_column :state
      aasm_initial_state :pending

      aasm_state :pending
      aasm_state :started
      aasm_state :passed
      aasm_state :failed
      aasm_state :cancelled

      aasm_event :start  do transitions :to => :started,     :from => [:pending]                    end
      aasm_event :pass   do transitions :to => :passed,      :from => [:pending, :started] end
      aasm_event :fail   do transitions :to => :failed,      :from => [:pending, :started] end
      aasm_event :cancel do transitions :to => :cancelled,   :from => [:started, :passed]           end
    end

end
