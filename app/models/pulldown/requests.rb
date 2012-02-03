module Pulldown::Requests
  module BaitLibraryRequest
    def self.included(base)
      base.class_eval do
        const_set(:DEFAULT_LIBRARY_TYPE, 'Agilent Pulldown')
        const_set(:LIBRARY_TYPES, [ 'Agilent Pulldown' ])

        fragment_size_details(100, 400)
      end
      base::Metadata.class_eval do
        include BaitLibrary::Associations
        association(:bait_library, :name)
        validates_presence_of :bait_library
      end
    end
  end

  # This is the billing strategy for the pulldown requests, which mimics the behaviour of the
  # general billing behaviour.
  module BillingStrategy
    def charge_to_project
      BillingEvent.bill_projects_for(self) if request_type.billable?
    end

    def charge_internally
      BillingEvent.bill_internally_for(self) if request_type.billable?
    end

    def refund_project
      BillingEvent.refund_projects_for(self) if request_type.billable?
    end
  end

  # Override the behaviour of Request so that we do not copy the aliquots from our source asset
  # to the target when we are passed.  This is actually done by the TransferRequest from plate
  # to plate as it goes through being processed.
  class LibraryCreation < Request
    include BillingStrategy

    def on_started
      # Override the default behaviour to not do the transfer
    end

    # Convenience helper for ensuring that the fragment size information is properly treated.
    # The columns in the database are strings and we need them to be integers, hence we force
    # that here.
    def self.fragment_size_details(minimum, maximum)
      class_eval do
        has_metadata :as => Request do
          # Redefine the fragment size attributes as they are fixed
          attribute(:fragment_size_required_from, :required => true, :in => [ minimum ], :default => minimum, :integer => true)
          attribute(:fragment_size_required_to,   :required => true, :in => [ maximum ], :default => maximum, :integer => true)
        end
        include Request::LibraryManufacture
      end
      const_get(:RequestOptionsValidator).class_eval do
        validates_inclusion_of :fragment_size_required_from, :in => [ minimum ], :allow_blank => true
        validates_inclusion_of :fragment_size_required_to,   :in => [ maximum ], :allow_blank => true
      end
      const_get(:Metadata).class_eval do
        def fragment_size_required_from
          self[:fragment_size_required_from].try(:to_i)
        end

        def fragment_size_required_to
          self[:fragment_size_required_to].try(:to_i)
        end
      end
    end
  end

  class WgsLibraryRequest < LibraryCreation
    DEFAULT_LIBRARY_TYPE = 'Standard'
    LIBRARY_TYPES        = [ DEFAULT_LIBRARY_TYPE ]

    fragment_size_details(300, 500)
  end

  class ScLibraryRequest < LibraryCreation
    include BaitLibraryRequest
  end

  class IscLibraryRequest < LibraryCreation
    include BaitLibraryRequest
  end
end
