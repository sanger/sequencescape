# frozen_string_literal: true
# Generates warehouse messages describing a Ultima Genomics Wafer. While wafers are not
# modeled directly in Sequencescape they can be approximated by a sequencing
# Wafers are equivalent to a flowcell in other sequencing platforms hence much of the code is similar to FlowcellIo
# {Batch}
class Api::Messages::UseqWaferIo < Api::Base
  self.includes = {
    requests: [
      {
        target_asset: {
          aliquots: [
            :library,
            { tag: :tag_group, sample: :uuid_object, study: :uuid_object, project: :uuid_object }
          ]
        }
      },
      :lab_events,
      :batch_request,
      :request_metadata
    ]
  }

  # The following modules add methods onto the relevant models, which are used below in generation of the
  # useq wafer MLWH message.
  # Included in UltimaSequencingRequest model
  module LaneExtensions
    def self.included(base) # rubocop:todo Metrics/MethodLength
      base.class_eval do
        # Lot numbers for opentron and amp
        # Matching descriptors from config/default_records/descriptors/003_ultima_descriptors.yml
        def otr_carrier_lot_number
          detect_descriptor('OTR carrier Lot #')
        end

        def otr_carrier_expiry
          detect_descriptor('OTR carrier expiry')
        end

        def otr_reaction_mix_7_lot_number
          detect_descriptor('Reaction Mix 7 Lot #')
        end

        def otr_reaction_mix_7_expiry
          detect_descriptor('Reaction Mix 7 expiry')
        end

        def otr_nfw_lot_number
          detect_descriptor('NFW Lot #')
        end

        def otr_nfw_expiry
          detect_descriptor('NFW expiry')
        end

        def otr_oil_lot_number
          detect_descriptor('Oil Lot #')
        end

        def otr_oil_expiry
          detect_descriptor('Oil expiry')
        end

        def otr_pipette_carousel
          detect_descriptor('Pipette carousel')
        end

        def otr_instrument_name
          detect_descriptor('Opentrons Inst. Name')
        end

        def amp_assign_control_bead_tube
          detect_descriptor('Assign Control Bead Tube')
        end

        def amp_instrument_name
          detect_descriptor('UG AMP Inst. Name')
        end
      end
    end
  end

  # Included in Aliquot model
  module AliquotExtensions
    # Finds the Ultima sequencing request associated with this aliquot's receptacle.
    # The receptacle is either the lane (target of the sequencing request, as in the
    # warehouse message interface) or the source tube (as in the sample sheet):
    # - Sample sheet: looks for all aliquots within the multiplexed library, with the
    #   sequencing request attached via +receptacle.requests+.
    # - Warehouse message: looks for aliquots within the lane, with the sequencing
    #   request attached via +receptacle.requests_as_target+.
    # @return [UltimaSequencingRequest, nil] the first matching request, if any
    def ultima_sequencing_request
      @ultima_sequencing_request ||=
        (receptacle.requests_as_target.to_a + receptacle.requests.to_a).grep(UltimaSequencingRequest).first
    end

    # @return [Boolean] whether the sequencing request is a UG200 request (otherwise UG100)
    def ultima_ug200?
      ultima_sequencing_request.is_a?(UltimaUG200SequencingRequest)
    end

    def ultima_application
      return if ultima_sequencing_request.nil?

      @ultima_application ||= nearest_ultima_conversion_request&.ultima_application
    end

    def ultima_preset
      return if ultima_application.nil?

      ultima_ug200? ? ultima_application&.ug200_preset : ultima_application&.ug100_preset
    end

    # @return [String] the preset's application type, or 'native' if there is no preset
    def ultima_application_type
      ultima_preset&.application_type || 'native'
    end

    def uga_primer
      return if ultima_application.nil?

      ultima_application.uga_primer.name
    end

    def ugb_primer
      return if ultima_application.nil?

      ultima_application.ugb_primer.name
    end

    # Finds the closest ancestor conversion request for an aliquot.
    # Searches parent labware one level at a time so nearer requests take precedence.
    # @return [UltimaConversionRequest, nil] the closest matching request, if any
    def nearest_ultima_conversion_request
      return @nearest_ultima_conversion_request if defined?(@nearest_ultima_conversion_request)

      @nearest_ultima_conversion_request = find_nearest_ultima_conversion_request
    end

    # rubocop:disable-next Style/SafeNavigationChainLength
    def illumina_tagged_wells
      @illumina_tagged_wells ||=
        begin
          # UltimaConversionRequest refers to the plate with the Ultima tags - so we need to check
          # from transfer_request - parent plate to get the plate with the Illumina tags
          conversion_request = nearest_ultima_conversion_request
          conversion_request&.asset&.transfer_requests_as_target&.flat_map(&:asset) || []
        end
    end

    # Aliquots in the converted wells belonging to this sample.
    def converted_illumina_aliquots
      @converted_illumina_aliquots ||=
        illumina_tagged_wells.flat_map(&:aliquots).select { |al| al.sample_id == sample_id }
    end

    def converted_illumina_tag
      return nil if converted_illumina_aliquots.empty?

      converted_illumina_aliquots.filter_map { |al| al.tag&.oligo }.first
    end

    def converted_illumina_tag2
      return nil if converted_illumina_aliquots.empty?

      converted_illumina_aliquots.filter_map { |al| al.tag2&.oligo }.first
    end

    private

    def find_nearest_ultima_conversion_request
      frontier = receptacle.parents
      until frontier.empty?
        conversion_request = conversion_request_for_ancestor_level(frontier, sample_id)
        return conversion_request if conversion_request

        frontier = frontier.flat_map(&:parents).uniq
      end
      nil
    end

    def conversion_request_for_ancestor_level(labware, sample_id)
      Aliquot
        .joins(:receptacle)
        .where(receptacles: { labware_id: labware.map(&:id) },
               aliquots: { sample_id: })
        .includes(:request)
        .filter_map(&:request)
        .find { |request| request.is_a?(UltimaConversionRequest) }
    end
  end

  # Batch is the main / top-level model that contributes to the message sent to the MLWH.
  renders_model(::Batch)

  # The following section maps attributes on Sequencescape models to attributes in the json message that is passed to
  # the MLWH.
  # The following methods come from the Batch model or the relevant module above.
  map_attribute_to_json_attribute(:id, 'wafer_id')

  map_attribute_to_json_attribute(:updated_at)

  # The following methods come from the Request model or the relevant module above.
  # They are included in the MLWH message under 'lanes'.
  with_nested_has_many_association(:requests, as: :lanes) do
    map_attribute_to_json_attribute(:position, 'request_order')
    map_attribute_to_json_attribute(:mx_library, 'id_pool_lims')
    map_attribute_to_json_attribute(:lane_identifier, 'entity_id_lims')
    map_attribute_to_json_attribute(:otr_instrument_name)
    map_attribute_to_json_attribute(:amp_instrument_name)
    map_attribute_to_json_attribute(:otr_carrier_lot_number)
    map_attribute_to_json_attribute(:otr_carrier_expiry)
    map_attribute_to_json_attribute(:otr_reaction_mix_7_lot_number)
    map_attribute_to_json_attribute(:otr_reaction_mix_7_expiry)
    map_attribute_to_json_attribute(:otr_nfw_lot_number)
    map_attribute_to_json_attribute(:otr_nfw_expiry)
    map_attribute_to_json_attribute(:otr_oil_lot_number)
    map_attribute_to_json_attribute(:otr_oil_expiry)
    map_attribute_to_json_attribute(:otr_pipette_carousel)
    map_attribute_to_json_attribute(:amp_assign_control_bead_tube)
    map_attribute_to_json_attribute(:ot_recipe)
    map_attribute_to_json_attribute(:id_wafer_lims)
    map_attribute_to_json_attribute(:wafer_size)
    map_attribute_to_json_attribute(:requested_sequencer_type, 'requested_sequencer_type')

    # The following methods come from the Aliquot model or the relevant module above.
    # They are included in the MLWH message under 'samples'.
    with_nested_has_many_association(:lane_samples, as: :samples) do
      with_association(:tag) do
        map_attribute_to_json_attribute(:oligo, 'tag_sequence')
      end
      map_attribute_to_json_attribute(:library_type, 'pipeline_id_lims')
      with_association(:bait_library) { map_attribute_to_json_attribute(:name, 'bait_name') }
      map_attribute_to_json_attribute(:insert_size_from, 'requested_insert_size_from')
      map_attribute_to_json_attribute(:insert_size_to, 'requested_insert_size_to')
      with_association(:sample) { map_attribute_to_json_attribute(:uuid, 'sample_uuid') }
      with_association(:study) { map_attribute_to_json_attribute(:uuid, 'study_uuid') }
      with_association(:primer_panel) { map_attribute_to_json_attribute(:name, 'primer_panel') }
      with_association(:library) { map_attribute_to_json_attribute(:external_identifier, 'id_library_lims') }
      map_attribute_to_json_attribute(:aliquot_type, 'entity_type')
      map_attribute_to_json_attribute(:converted_illumina_tag)
      map_attribute_to_json_attribute(:converted_illumina_tag2)
      map_attribute_to_json_attribute(:ultima_application_type, 'application_type')
      map_attribute_to_json_attribute(:uga_primer)
      map_attribute_to_json_attribute(:ugb_primer)
    end
  end
end
