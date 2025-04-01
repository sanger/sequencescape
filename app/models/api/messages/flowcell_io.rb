# frozen_string_literal: true
# Generates warehouse messages describing a flowcell. While flowcells are not
# modeled directly in Sequencescape they can be approximated by a sequencing
# {Batch}
class Api::Messages::FlowcellIo < Api::Base
  MANUAL_QC_BOOLS = { 'passed' => true, 'failed' => false }.freeze

  self.includes = {
    requests: [
      {
        target_asset: {
          aliquots: [
            :aliquot_index,
            :library,
            { tag: :tag_group, tag2: :tag_group, sample: :uuid_object, study: :uuid_object, project: :uuid_object }
          ]
        }
      },
      :lab_events,
      :batch_request,
      :request_metadata
    ]
  }

  # The following modules add methods onto the relevant models, which are used below in generation of the flowcell MLWH
  # message.
  # Included in SequencingRequest model
  module LaneExtensions
    def self.included(base) # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
      base.class_eval do
        def mx_library
          asset.external_identifier
        end

        def manual_qc
          MANUAL_QC_BOOLS[target_asset.try(:qc_state)]
        end

        def flowcell_barcode
          detect_descriptor(flowcell_identifier)
        end

        def lane_samples
          target_asset.aliquots
        end

        def lane
          target_asset.labware
        end

        delegate :spiked_in_buffer, :external_release, to: :lane, allow_nil: true

        def controls
          spiked_in_buffer.present? ? spiked_in_buffer.aliquots : []
        end

        def lane_identifier
          target_asset_id
        end

        def request_purpose_key
          request_purpose.try(:key)
        end

        def workflow
          detect_descriptor('Workflow (Standard or Xp)')
        end

        def spiked_phix_barcode
          spiked_in_buffer&.human_barcode
        end

        def spiked_phix_percentage
          detect_float_descriptor('PhiX %', '%')
        end

        def loading_concentration
          detect_float_descriptor('Lane loading concentration (pM)', 'pM')
        end

        # Currently the tangled mass that is descriptors does little in the way of validation
        # This means non-float values have been entered in some case (such as ranges)
        # This extracts floats only until the data can be repaired, and validation added to prevent
        # bad data from being added in future
        def detect_float_descriptor(name, ignored_unit)
          value = detect_descriptor(name)
          return nil if value.nil?

          # If someone has added the units to the input, strip them off then convert to a float
          # We also strip whitespace.
          # However if float conversion fails, then the input is unsuitable.
          # Note: .to_f is too permissive here
          Float(value.gsub(ignored_unit, '').strip, exception: false)
        end
      end
    end
  end

  # Included in ControlRequest model
  module ControlLaneExtensions
    def self.included(base) # rubocop:todo Metrics/MethodLength
      base.class_eval do
        def mx_library
          asset.external_identifier || 'UNKNOWN'
        end

        def manual_qc
          MANUAL_QC_BOOLS[target_asset.try(:qc_state)]
        end

        def lane_samples
          []
        end

        def product_line
          nil
        end

        def spiked_in_buffer
          false
        end

        def spiked_phix_barcode
          nil
        end

        def spiked_phix_percentage
          nil
        end

        def loading_concentration
          nil
        end

        def workflow
          nil
        end

        def external_release
          false
        end

        def controls
          asset.aliquots
        end

        def lane_identifier
          'control_lane'
        end
      end
    end
  end

  # Included in Aliquot model
  module AliquotExtensions
    def aliquot_type
      tags? ? 'library_indexed' : 'library'
    end

    def control_aliquot_type
      tags? ? 'library_indexed_spike' : 'library_control'
    end
  end

  # Included in Project model
  module ProjectExtensions
    def project_cost_code_for_uwh
      project_cost_code.length > 20 ? 'Custom' : project_cost_code
    end
  end

  # Included in Batch model
  module Extensions
    module ClassMethods
    end

    def self.included(base)
      base.class_eval do
        extend ClassMethods

        def flowcell_barcode
          requests.first&.flowcell_barcode
        end

        def read_length
          requests.first&.request_metadata&.read_length
        end

        # We alias is as the json generator assumes each method is called only once.
        alias_method :reverse_read_length, :read_length
      end
    end
  end

  # Batch is the main / top-level model that contributes to the message sent to the MLWH.
  renders_model(::Batch)

  # The following section maps attributes on Sequencescape models to attributes in the json message that is passed to
  # the MLWH.
  # The following methods come from the Batch model or the relevant module above.
  map_attribute_to_json_attribute(:flowcell_barcode)
  map_attribute_to_json_attribute(:id, 'flowcell_id')
  map_attribute_to_json_attribute(:read_length, 'forward_read_length')
  map_attribute_to_json_attribute(:reverse_read_length, 'reverse_read_length')

  map_attribute_to_json_attribute(:updated_at)

  # The following methods come from the Request model or the relevant module above.
  # They are included in the MLWH message under 'lanes'.
  with_nested_has_many_association(:requests, as: :lanes) do
    map_attribute_to_json_attribute(:manual_qc)
    map_attribute_to_json_attribute(:position)
    map_attribute_to_json_attribute(:priority)
    map_attribute_to_json_attribute(:mx_library, 'id_pool_lims')
    map_attribute_to_json_attribute(:external_release, 'external_release')
    map_attribute_to_json_attribute(:lane_identifier, 'entity_id_lims')
    map_attribute_to_json_attribute(:product_line, 'team')
    map_attribute_to_json_attribute(:request_purpose, 'purpose')
    map_attribute_to_json_attribute(:spiked_phix_barcode)
    map_attribute_to_json_attribute(:spiked_phix_percentage)
    map_attribute_to_json_attribute(:workflow)
    map_attribute_to_json_attribute(:loading_concentration)

    # The following methods come from the Aliquot model or the relevant module above.
    # They are included in the MLWH message under 'samples'.
    with_nested_has_many_association(:lane_samples, as: :samples) do
      map_attribute_to_json_attribute(:aliquot_index_value, 'tag_index')
      map_attribute_to_json_attribute(:suboptimal, 'suboptimal')

      with_association(:tag) do
        map_attribute_to_json_attribute(:oligo, 'tag_sequence')
        map_attribute_to_json_attribute(:tag_group_id, 'tag_set_id_lims')
        with_association(:tag_group) { map_attribute_to_json_attribute(:name, 'tag_set_name') }
        map_attribute_to_json_attribute(:map_id, 'tag_identifier')
      end
      with_association(:tag2) do
        map_attribute_to_json_attribute(:oligo, 'tag2_sequence')
        map_attribute_to_json_attribute(:tag_group_id, 'tag2_set_id_lims')
        with_association(:tag_group) { map_attribute_to_json_attribute(:name, 'tag2_set_name') }
        map_attribute_to_json_attribute(:map_id, 'tag2_identifier')
      end
      map_attribute_to_json_attribute(:library_type, 'pipeline_id_lims')
      with_association(:bait_library) { map_attribute_to_json_attribute(:name, 'bait_name') }
      map_attribute_to_json_attribute(:insert_size_from, 'requested_insert_size_from')
      map_attribute_to_json_attribute(:insert_size_to, 'requested_insert_size_to')
      with_association(:sample) { map_attribute_to_json_attribute(:uuid, 'sample_uuid') }
      with_association(:study) { map_attribute_to_json_attribute(:uuid, 'study_uuid') }
      with_association(:project) do
        map_attribute_to_json_attribute(:project_cost_code_for_uwh, 'cost_code')
        map_attribute_to_json_attribute(:r_and_d?, 'is_r_and_d')
      end
      with_association(:primer_panel) { map_attribute_to_json_attribute(:name, 'primer_panel') }
      with_association(:library) { map_attribute_to_json_attribute(:external_identifier, 'id_library_lims') }
      map_attribute_to_json_attribute(:library_id, 'legacy_library_id')
      map_attribute_to_json_attribute(:aliquot_type, 'entity_type')
    end

    # The following methods come from the Aliquot model or the relevant module above.
    # They are included in the MLWH message under 'controls'.
    with_nested_has_many_association(:controls) do
      with_association(:tag) do
        map_attribute_to_json_attribute(:map_id, 'tag_index')
        map_attribute_to_json_attribute(:oligo, 'tag_sequence')
        map_attribute_to_json_attribute(:tag_group_id, 'tag_set_id_lims')
        with_association(:tag_group) { map_attribute_to_json_attribute(:name, 'tag_set_name') }
      end
      with_association(:tag2) do
        map_attribute_to_json_attribute(:oligo, 'tag2_sequence')
        map_attribute_to_json_attribute(:tag_group_id, 'tag2_set_id_lims')
        with_association(:tag_group) { map_attribute_to_json_attribute(:name, 'tag2_set_name') }
        map_attribute_to_json_attribute(:map_id, 'tag2_identifier')
      end
      map_attribute_to_json_attribute(:library_type, 'pipeline_id_lims')
      with_association(:sample) { map_attribute_to_json_attribute(:uuid, 'sample_uuid') }
      with_association(:study) { map_attribute_to_json_attribute(:uuid, 'study_uuid') }
      map_attribute_to_json_attribute(:library_id, 'legacy_library_id')
      with_association(:library) { map_attribute_to_json_attribute(:external_identifier, 'id_library_lims') }
      map_attribute_to_json_attribute(:control_aliquot_type, 'entity_type')
    end
  end
end
