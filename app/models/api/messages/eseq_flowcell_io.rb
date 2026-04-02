# frozen_string_literal: true
# Generates warehouse messages describing an Element Aviti flowcell.
# This is a subset of FlowcellIo containing only fields required by Eseq.
class Api::Messages::EseqFlowcellIo < Api::Base
  self.includes = {
    requests: [
      {
        target_asset: {
          aliquots: [
            :library,
            :bait_library,
            :primer_panel,
            { tag: :tag_group, tag2: :tag_group, sample: :uuid_object, study: :uuid_object }
          ]
        }
      },
      :batch_request
    ]
  }

  # The following modules add methods onto the relevant models, which are used below in generation of the
  # eseq flowcel  MLWH message.
  # Included in SequencingRequest model
  module LaneExtensions
    def self.included(base)
      base.class_eval do
        def quant_method_used
          detect_descriptor('Quant method used')
        end

        def custom_primer_kit_used
          detect_descriptor('Custom primer kit used')
        end
      end
    end
  end

  renders_model(::Batch)

  map_attribute_to_json_attribute(:id, 'flowcell_id')
  map_attribute_to_json_attribute(:updated_at)

  with_nested_has_many_association(:requests, as: :lanes) do
    map_attribute_to_json_attribute(:position, 'lane')
    map_attribute_to_json_attribute(:mx_library, 'id_pool_lims')
    map_attribute_to_json_attribute(:lane_identifier, 'entity_id_lims')
    map_attribute_to_json_attribute(:request_purpose, 'purpose')
    map_attribute_to_json_attribute(:quant_method_used)
    map_attribute_to_json_attribute(:custom_primer_kit_used)

    with_nested_has_many_association(:lane_samples, as: :samples) do
      with_association(:tag) { map_attribute_to_json_attribute(:oligo, 'tag_sequence') }
      with_association(:tag2) { map_attribute_to_json_attribute(:oligo, 'tag2_sequence') }
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
      with_association(:tag) { map_attribute_to_json_attribute(:oligo, 'tag_sequence') }
      with_association(:tag2) { map_attribute_to_json_attribute(:oligo, 'tag2_sequence') }
      map_attribute_to_json_attribute(:library_type, 'pipeline_id_lims')
      with_association(:sample) { map_attribute_to_json_attribute(:uuid, 'sample_uuid') }
      with_association(:study) { map_attribute_to_json_attribute(:uuid, 'study_uuid') }
      with_association(:library) { map_attribute_to_json_attribute(:external_identifier, 'id_library_lims') }
      map_attribute_to_json_attribute(:control_aliquot_type, 'entity_type')
    end
  end
end
