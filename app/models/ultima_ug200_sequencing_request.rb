# frozen_string_literal: true

# Request class specific to the Ultima UG200 sequencing platform.
# Includes specific validation for wafer combination with read type.
class UltimaUG200SequencingRequest < SequencingRequest
  include Api::Messages::UseqWaferIo::LaneExtensions

  has_metadata as: Request do
    # Defining the sequencing request metadata here again, as 'has_metadata'
    # does not automatically append these custom attributes to the request.
    #
    # The has_metadata call dynamically defines an inner Metadata class and
    # takes the attributes from the block and adds them to the Metadata class.
    # There is an assumption that the inner Metadata class is available in a
    # sequencing request class defintion. Calling has_metadata again does not
    # inherit the attributes given in the block supplied in the superclass.
    # They need to be supplied again for this class for a proper inner Metadata
    # class definition. In a future refactoring these attributes can be moved a
    # class attribute and subclasses can merge its own attibutes to that. A
    # common method can set up the inner Metadata class in the subclasses.
    custom_attribute(:fragment_size_required_from, integer: true, minimum: 1)
    custom_attribute(:fragment_size_required_to, integer: true, minimum: 1)

    # TODO: the defaults set here do NOT work on the option lists in the bulk submission screen,
    # but do work on the request additional sequencing screen for some reason.
    custom_attribute(:wafer_size, default: '10TB', validator: true, required: true, selection: true)
    custom_attribute(:read_length, default: 300, integer: true, validator: true, required: true, selection: true)
  end

  # Delegate to request_metadata so the attributes are visible to the validator in the RSpec tests.
  # This delegation has no real effect outside of the tests.
  delegate :wafer_size, :read_length, to: :request_metadata

  class UltimaUG200RequestOptionsValidator < DelegateValidation::Validator
    delegate :wafer_size, :read_length, :request_types, to: :target

    validate :validate_read_length_by_wafer_size

    def validate_read_length_by_wafer_size
      return if wafer_size == '10TB' && read_length.to_i == 300

      errors.add(:read_length,
                 'The user can only select a Read Length of 300 with the 10TB wafer type for Ultima UG200 requests')
    end
  end

  def self.delegate_validator
    UltimaUG200SequencingRequest::UltimaUG200RequestOptionsValidator
  end

  # Generates unique wafer ID, concatenation of batch_for_opentrons,
  # id_pool_lims, and request_order.
  # @return [String] unique wafer ID for LIMS
  def id_wafer_lims
    "#{batch.id}_#{source_labware.human_barcode}_#{position}"
  end
end
