# frozen_string_literal: true

class UltimaSequencingRequest < SequencingRequest
  include Api::Messages::UseqWaferIo::LaneExtensions

  FREE = 'Free'
  FLEX = 'Flex'
  OT_RECIPE_OPTIONS = [FREE, FLEX].freeze

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

    custom_attribute(:ot_recipe, default: FREE, in: OT_RECIPE_OPTIONS, required: true)
    enum :ot_recipe, { Free: 0, Flex: 1 }
  end

  # Delegate to request_metadata so the attributes are visible to the validator in the RSpec tests.
  # This delegation has no real effect outside of the tests.
  delegate :ot_recipe, to: :request_metadata

  # Generates unique wafer ID, concatenation of batch_for_opentrons,
  # id_pool_lims, and request_order.
  # @return [String] unique wafer ID for LIMS
  def id_wafer_lims
    return nil unless batch && source_labware && position

    "#{batch.id}_#{source_labware.human_barcode}_#{position}"
  end
end
