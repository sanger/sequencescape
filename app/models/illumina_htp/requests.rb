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
      submission.next_requests(self).each {|r| r.pending? ? r.cancel_before_started! : r.transition_to('failed') unless r.failed? }
    end

    validate :valid_purpose?
    def valid_purpose?
      return true if request_type.acceptable_plate_purposes.include?(asset.plate.purpose)
      errors.add("#{asset.plate.purpose.name} is not a suitable plate purpose.")
      false
    end

  end

  class LibraryCompletion < StdLibraryRequest
    module FailUpstream
      def on_failed
        asset.requests_as_target.select {|r| r.passed? && r.is_a?(SharedLibraryPrep) }.map do |r|
          r.change_decision! unless r.failed?
        end
      end
    end
    include FailUpstream
  end

  module InitialDownstream
    def outer_request
      asset.requests.detect {|request| request.is_a?(LibraryCompletion)}
    end
  end

  class CherrypickedToShear < TransferRequest
    include TransferRequest::InitialTransfer
  end

  class CovarisToSheared < TransferRequest
    redefine_state_machine do
      aasm_column :state
      aasm_initial_state :pending

      aasm_state :pending
      aasm_state :started
      aasm_state :passed
      aasm_state :qc_complete
      aasm_state :failed
      aasm_state :cancelled

      aasm_event :start  do transitions :to => :started,     :from => [:pending]                    end
      aasm_event :pass   do transitions :to => :passed,      :from => [:pending, :started, :failed] end
      aasm_event :qc     do transitions :to => :qc_complete, :from => [:passed]                     end
      aasm_event :fail   do transitions :to => :failed,      :from => [:pending, :started, :passed] end
      aasm_event :cancel do transitions :to => :cancelled,   :from => [:started, :passed]           end
    end
  end

  class PostShearToAlLibs < TransferRequest
    redefine_state_machine do
      # The statemachine for transfer requests is more promiscuous than normal requests, as well
      # as being more concise as it has less states.
      aasm_column :state
      aasm_state :pending
      aasm_state :started
      aasm_state :fx_transfer
      aasm_state :failed,     :enter => :on_failed
      aasm_state :passed
      aasm_state :cancelled,  :enter => :on_cancelled
      aasm_initial_state :pending

      # State Machine events
      aasm_event :start do
        transitions :to => :started, :from => [:pending]
      end

      aasm_event :pass do
        transitions :to => :passed, :from => [:fx_transfer, :failed]
      end

      aasm_event :fail do
        transitions :to => :failed, :from => [:pending, :started, :passed]
      end

      aasm_event :cancel do
        transitions :to => :cancelled, :from => [:started, :passed]
      end

      aasm_event :cancel_before_started do
        transitions :to => :cancelled, :from => [:pending]
      end

      aasm_event :detach do
        transitions :to => :pending, :from => [:pending]
      end

      aasm_event :fx_transfer do
        transitions :to => :fx_transfer, :from => [:started]
      end

    end
  end

  class PrePcrToPcr < TransferRequest
    redefine_state_machine do
      aasm_column :state
      aasm_initial_state :pending

      aasm_state :pending
      aasm_state :started_fx
      aasm_state :started_mj
      aasm_state :passed
      aasm_state :failed
      aasm_state :cancelled

      aasm_event :start_fx do transitions :to => :started_fx,  :from => [:pending]                                    end
      aasm_event :start_mj do transitions :to => :started_mj,  :from => [:started_fx]                                 end
      aasm_event :pass     do transitions :to => :passed,      :from => [:pending, :started_mj, :failed]              end
      aasm_event :fail     do transitions :to => :failed,      :from => [:pending, :started_fx, :started_mj, :passed] end
      aasm_event :cancel   do transitions :to => :cancelled,   :from => [:started_fx, :started_mj, :passed]           end
    end
  end

  class PcrToPcrXp < TransferRequest
    redefine_state_machine do
      aasm_column :state
      aasm_initial_state :pending

      aasm_state :pending
      aasm_state :started
      aasm_state :passed
      aasm_state :qc_complete
      aasm_state :failed
      aasm_state :cancelled

      aasm_event :start  do transitions :to => :started,     :from => [:pending]                    end
      aasm_event :pass   do transitions :to => :passed,      :from => [:pending, :started, :failed] end
      aasm_event :qc     do transitions :to => :qc_complete, :from => [:passed]                     end
      aasm_event :fail   do transitions :to => :failed,      :from => [:pending, :started, :passed] end
      aasm_event :cancel do transitions :to => :cancelled,   :from => [:started, :passed, :qc]      end
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

 class PcrXpToStock < TransferRequest
    redefine_state_machine do
      aasm_column :state
      aasm_initial_state :pending

      aasm_state :pending
      aasm_state :started
      aasm_state :passed
      aasm_state :qc_complete
      aasm_state :failed
      aasm_state :cancelled

      aasm_event :start  do transitions :to => :started,     :from => [:pending]                    end
      aasm_event :pass   do transitions :to => :passed,      :from => [:pending, :started, :failed] end
      aasm_event :qc     do transitions :to => :qc_complete, :from => [:passed]                     end
      aasm_event :fail   do transitions :to => :failed,      :from => [:pending, :started, :passed] end
      aasm_event :cancel do transitions :to => :cancelled,   :from => [:started, :passed, :qc]      end
    end
  end

  class PcrXpToPool < PcrXpToStock
    include InitialDownstream
  end

  class LibPoolSsToLibPoolSsXp < TransferRequest
    redefine_state_machine do
      aasm_column :state
      aasm_initial_state :pending

      aasm_state :pending
      aasm_state :started
      aasm_state :passed
      aasm_state :qc_complete
      aasm_state :failed
      aasm_state :cancelled

      aasm_event :start  do transitions :to => :started,     :from => [:pending]                    end
      aasm_event :pass   do transitions :to => :passed,      :from => [:pending, :started, :failed] end
      aasm_event :qc     do transitions :to => :qc_complete, :from => [:passed]                     end
      aasm_event :fail   do transitions :to => :failed,      :from => [:pending, :started, :passed] end
      aasm_event :cancel do transitions :to => :cancelled,   :from => [:started, :passed, :qc]      end
    end
  end

  class LibPoolToLibPoolNorm < TransferRequest
    redefine_state_machine do
      aasm_column :state
      aasm_initial_state :pending

      aasm_state :pending
      aasm_state :started
      aasm_state :passed
      aasm_state :qc_complete
      aasm_state :failed
      aasm_state :cancelled

      aasm_event :start  do transitions :to => :started,     :from => [:pending]                    end
      aasm_event :pass   do transitions :to => :passed,      :from => [:pending, :started, :failed] end
      aasm_event :qc     do transitions :to => :qc_complete, :from => [:passed]                     end
      aasm_event :fail   do transitions :to => :failed,      :from => [:pending, :started, :passed] end
      aasm_event :cancel do transitions :to => :cancelled,   :from => [:started, :passed, :qc]      end
    end
  end

end
