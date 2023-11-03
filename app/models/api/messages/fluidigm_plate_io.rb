# frozen_string_literal: true
# Generates warehouse messages describing a fluidigm plate.
class Api::Messages::FluidigmPlateIO < Api::Base
  self.includes = [
    :barcodes,
    :uuid_object,
    { wells: [:map, :uuid_object, { primary_aliquot: [:project, { sample: :uuid_object, study: :uuid_object }] }] }
  ]

  module WellExtensions
    def cost_code
      return nil if primary_aliquot.nil?

      primary_aliquot.project.project_cost_code
    end

    def primary_sample_uuid
      return nil if primary_aliquot.nil?

      primary_aliquot.sample.uuid
    end

    def primary_study_uuid
      return nil if primary_aliquot.nil?

      primary_aliquot.study.uuid
    end

    # Untracked for the moment
    def qc_state
      nil
    end
  end

  renders_model(::Plate)

  map_attribute_to_json_attribute(:id, 'id_flgen_plate_lims')
  map_attribute_to_json_attribute(:human_barcode, 'plate_barcode_lims')
  map_attribute_to_json_attribute(:fluidigm_barcode, 'plate_barcode')
  map_attribute_to_json_attribute(:uuid, 'plate_uuid_lims')
  map_attribute_to_json_attribute(:size, 'plate_size')

  # rubocop:todo Layout/LineLength
  map_attribute_to_json_attribute(:updated_at, 'last_updated') # We do it for the whole plate to ensure the message has a timestamp

  # rubocop:enable Layout/LineLength
  map_attribute_to_json_attribute(:occupied_well_count, 'plate_size_occupied')

  with_nested_has_many_association(:wells_in_row_order, as: :wells) do
    map_attribute_to_json_attribute(:map_description, 'well_label')
    map_attribute_to_json_attribute(:uuid, 'well_uuid_lims')
    map_attribute_to_json_attribute(:cost_code, 'cost_code')
    map_attribute_to_json_attribute(:primary_sample_uuid, 'sample_uuid')
    map_attribute_to_json_attribute(:primary_study_uuid, 'study_uuid')
    map_attribute_to_json_attribute(:qc_state, 'qc_state')
  end
end
