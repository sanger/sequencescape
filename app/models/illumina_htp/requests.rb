#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013,2014,2015,2016 Genome Research Ltd.

module IlluminaHtp::Requests

  class StdLibraryRequest < Request::LibraryCreation

    fragment_size_details(:no_default, :no_default)

    # Ensure that the bait library information is also included in the pool information.
    def update_pool_information(pool_information)
      super
      pool_information[:target_tube_purpose] = target_tube.purpose.uuid if target_tube
      pool_information[:request_type] = request_type.key
    end

    def role
      order.role
    end

  end

  class SharedLibraryPrep < StdLibraryRequest
    def target_tube
      @target_tube ||= submission.next_requests(self).detect {|r| r.target_tube }.try(:target_tube)
    end

    def on_failed
      submission.next_requests(self).each(&:failed_upstream!)
    end

    validate :valid_purpose?
    def valid_purpose?
      return true if request_type.acceptable_plate_purposes.include?(asset.plate.purpose)
      errors.add(:asset,"#{asset.plate.purpose.name} is not a suitable plate purpose.")
      false
    end

    def failed_downstream!
      change_decision! unless failed?
    end

  end

  class LibraryCompletion < StdLibraryRequest
    module FailUpstream
      def on_failed
        asset.requests_as_target.each(&:failed_downstream!)
      end
    end
    include FailUpstream
  end

  module InitialDownstream
    def outer_request
      asset.requests.detect {|request| request.library_creation? && request.submission_id == self.submission_id }
    end
  end

  class CherrypickedToShear < TransferRequest
    include TransferRequest::InitialTransfer
  end

  class PostShearToAlLibs < TransferRequest
    redefine_state_machine do
      aasm_column :state
      aasm_state :pending
      aasm_state :started
      aasm_state :fx_transfer
      aasm_state :failed,     :enter => :on_failed
      aasm_state :passed
      aasm_state :cancelled,  :enter => :on_cancelled
      aasm_initial_state :pending

      aasm_event :start                 do transitions :to => :started, :from => [:pending] end
      aasm_event :pass                  do transitions :to => :passed, :from => [:pending, :started, :fx_transfer, :failed] end
      aasm_event :fail                  do transitions :to => :failed, :from => [:pending, :started, :passed] end
      aasm_event :cancel                do transitions :to => :cancelled, :from => [:started, :passed] end
      aasm_event :cancel_before_started do transitions :to => :cancelled, :from => [:pending] end
      aasm_event :detach                do transitions :to => :pending, :from => [:pending] end
      aasm_event :fx_transfer           do transitions :to => :fx_transfer, :from => [:started] end

    end
  end

  class PcrXpToPoolPippin < TransferRequest
    include InitialDownstream
    redefine_state_machine do
      aasm_column :state
      aasm_initial_state :pending

      aasm_state :pending
      aasm_state :started
      aasm_state :passed
      aasm_state :cancelled

      aasm_event :start  do transitions :to => :started,     :from => [:pending]                    end
      aasm_event :pass   do transitions :to => :passed,      :from => [:pending, :started, :failed] end
      aasm_event :cancel do transitions :to => :cancelled,   :from => [:started, :passed, :qc]      end
    end
  end

  class PcrXpToPool < TransferRequest
    include InitialDownstream
  end

end
