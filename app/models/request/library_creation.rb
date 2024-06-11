# frozen_string_literal: true
class Request::LibraryCreation < CustomerRequest
  self.library_creation = true

  # Override the behaviour of Request so that we do not copy the aliquots from our source asset
  # to the target when we are passed.  This is actually done by the TransferRequest from plate
  # to plate as it goes through being processed.

  def on_started
    # Override the default behaviour to not do the transfer
  end

  # Add common pool information, like insert size and library type
  def update_pool_information(pool_information)
    pool_information.merge!(
      insert_size: {
        from: insert_size.from,
        to: insert_size.to
      },
      library_type: {
        name: library_type
      }
    )
  end

  # Convenience helper for ensuring that the fragment size information is properly treated.
  # The columns in the database are strings and we need them to be integers, hence we force
  # that here.
  def self.fragment_size_details(minimum = :no_default, maximum = :no_default) # rubocop:todo Metrics/MethodLength
    minimum_details = { required: true, integer: true, minimum: 1 }
    maximum_details = { required: true, integer: true, minimum: 1 }
    minimum_details[:default] = minimum unless minimum == :no_default
    maximum_details[:default] = maximum unless maximum == :no_default

    class_eval do
      has_metadata as: Request do
        # Redefine the fragment size attributes as they are fixed
        custom_attribute(:fragment_size_required_from, minimum_details)
        custom_attribute(:fragment_size_required_to, maximum_details)
        custom_attribute(:gigabases_expected, positive_float: true)
      end
      include Request::LibraryManufacture
    end
    const_get(:Metadata).class_eval do
      def fragment_size_required_from
        super.try(:to_i)
      end

      def fragment_size_required_to
        super.try(:to_i)
      end
    end
  end

  has_metadata as: Request do
  end

  #
  # Passed into cloned aliquots at the beginning of a pipeline to set
  # appropriate options
  #
  #
  # @return [Hash] A hash of aliquot attributes
  #
  def aliquot_attributes
    {
      study_id: initial_study_id,
      project_id: initial_project_id,
      library_type:,
      insert_size:,
      request_id: id
    }
  end

  include Request::CustomerResponsibility
end
