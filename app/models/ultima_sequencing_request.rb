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
    "#{batch.id}_#{source_labware.human_barcode}_#{position}"
  end

  # Returns the sequencer type 'UG 100' for UltimaSequencingRequest.
  def requested_sequencer_type
    'UG 100'
  end

  # Returns the wafer size for UltimaSequencingRequest as nil, as not tracked in UG100
  def wafer_size
    nil
  end

  # Returns the application type from the nearest ancestor conversion request, or the default.
  # @param aliquot [Aliquot] the aliquot whose application type is needed
  # @return [String] the application type
  def application_type_for_aliquot(aliquot)
    preset_for_aliquot(aliquot)&.application_type || 'native'
  end

  # Returns the UG100 preset for the given aliquot, if any.
  # @param aliquot [Aliquot] the aliquot whose preset is needed
  # @return [UltimaPreset, nil] the UG100 preset
  def preset_for_aliquot(aliquot)
    nearest_ultima_conversion_request_for(aliquot)&.ultima_application&.ug100_preset
  end

  # Finds the closest ancestor conversion request for an aliquot.
  # Searches parent labware one level at a time so nearer requests take precedence.
  # @param aliquot [Aliquot] the aliquot whose ancestors to search
  # @return [UltimaConversionRequest, nil] the closest matching request, if any
  def nearest_ultima_conversion_request_for(aliquot)
    frontier = aliquot.receptacle.parents.to_a

    until frontier.empty?
      conversion_request = conversion_request_for_ancestor_level(frontier)
      return conversion_request if conversion_request

      frontier = frontier.flat_map(&:parents).uniq
    end

    nil
  end

  private

  def conversion_request_for_ancestor_level(labware)
    Aliquot
      .joins(:receptacle)
      .where(receptacles: { labware_id: labware.map(&:id) })
      .includes(:request)
      .filter_map(&:request)
      .find { |request| request.is_a?(UltimaConversionRequest) }
  end
end
