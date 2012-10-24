module IlluminaB::Requests

  class StdLibraryRequest < Request::LibraryCreation
    LIBRARY_TYPES = [
      "No PCR",
      "High complexity and double size selected",
      "Illumina cDNA protocol",
      "Agilent Pulldown",
      "Custom",
      "High complexity",
      "ChiP-seq",
      "NlaIII gene expression",
      "Standard",
      "Long range",
      "Small RNA",
      "Double size selected",
      "DpnII gene expression",
      "TraDIS",
      "qPCR only",
      "Pre-quality controlled",
      "DSN_RNAseq"
    ]

    DEFAULT_LIBRARY_TYPE = 'Standard'

    fragment_size_details(:no_default, :no_default)
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
end
