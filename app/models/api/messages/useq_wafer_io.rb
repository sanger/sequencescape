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
        def wafer_barcode
          detect_descriptor(flowcell_identifier)
        end

        # Lot numbers for opentron and amp
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

  # Included in ControlRequest model
  module ControlLaneExtensions
    def self.included(base) # rubocop:todo Metrics/MethodLength
      base.class_eval do
        # Lot numbers for opentron and amp
        def otr_carrier_lot_number
          nil
        end

        def otr_carrier_expiry
          nil
        end

        def otr_reaction_mix_7_lot_number
          nil
        end

        def otr_reaction_mix_7_expiry
          nil
        end

        def otr_nfw_lot_number
          nil
        end

        def otr_nfw_expiry
          nil
        end

        def otr_oil_lot_number
          nil
        end

        def otr_oil_expiry
          nil
        end

        def otr_pipette_carousel
          nil
        end

        def otr_instrument_name
          nil
        end

        def amp_assign_control_bead_tube
          nil
        end

        def amp_instrument_name
          nil
        end
      end
    end
  end

  # Included in Batch model
  module Extensions
    module ClassMethods
    end

    def self.included(base)
      base.class_eval do
        extend ClassMethods

        def wafer_barcode
          requests.first&.flowcell_barcode
        end
      end
    end
  end

  # Batch is the main / top-level model that contributes to the message sent to the MLWH.
  renders_model(::Batch)

  # The following section maps attributes on Sequencescape models to attributes in the json message that is passed to
  # the MLWH.
  # The following methods come from the Batch model or the relevant module above.
  map_attribute_to_json_attribute(:wafer_barcode)
  map_attribute_to_json_attribute(:id, 'wafer_id')

  map_attribute_to_json_attribute(:updated_at)

  # The following methods come from the Request model or the relevant module above.
  # They are included in the MLWH message under 'lanes'.
  with_nested_has_many_association(:requests, as: :lanes) do
    map_attribute_to_json_attribute(:position)
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
    end

    # The following methods come from the Aliquot model or the relevant module above.
    # They are included in the MLWH message under 'controls'.
    with_nested_has_many_association(:controls) do
      with_association(:tag) do
        map_attribute_to_json_attribute(:oligo, 'tag_sequence')
      end
      map_attribute_to_json_attribute(:library_type, 'pipeline_id_lims')
      with_association(:sample) { map_attribute_to_json_attribute(:uuid, 'sample_uuid') }
      with_association(:study) { map_attribute_to_json_attribute(:uuid, 'study_uuid') }
      with_association(:library) { map_attribute_to_json_attribute(:external_identifier, 'id_library_lims') }
      map_attribute_to_json_attribute(:control_aliquot_type, 'entity_type')
    end
  end
end
