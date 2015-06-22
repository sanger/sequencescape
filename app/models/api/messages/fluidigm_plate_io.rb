#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class Api::Messages::FluidigmPlateIO < Api::Base

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

    def qc_state # Untracked for the moment
      nil
    end

  end

  renders_model(::Plate)

  map_attribute_to_json_attribute(:id,'id_flgen_plate_lims')
  map_attribute_to_json_attribute(:sanger_human_barcode,'plate_barcode_lims')
  map_attribute_to_json_attribute(:fluidigm_barcode,'plate_barcode')
  map_attribute_to_json_attribute(:uuid,'plate_uuid_lims')
  map_attribute_to_json_attribute(:size,'plate_size')
  map_attribute_to_json_attribute(:updated_at,'last_updated') # We do it for the whole plate to ensure the message has a timestamp

  with_nested_has_many_association(:wells) do
     map_attribute_to_json_attribute(:map_description,     'well_label')
     map_attribute_to_json_attribute(:uuid,                'well_uuid_lims')
     map_attribute_to_json_attribute(:cost_code,           'cost_code')
     map_attribute_to_json_attribute(:primary_sample_uuid, 'sample_uuid')
     map_attribute_to_json_attribute(:primary_study_uuid,  'study_uuid')
     map_attribute_to_json_attribute(:qc_state,            'qc_state')
  end


end


