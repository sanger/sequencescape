

# frozen_string_literal: true

namespace :pac_bio_run do
  desc 'Update all PacBio runs in the warehouse where there is a duplicate for the index ' +
  '[id_pac_bio_run_lims, well_label, comparable_tag_identifier, comparable_tag2_identifier]' +
  ' because there is more than one sequencing request for the run'

  task rebroadcast_duplicates: :environment do
    class Receptacle < Asset
      def most_recent_active_requests_as_target_group_by_same_source
          requests_as_target.where(state: ['started']).group(:asset_id).having("created_at=max(created_at)")
      end    
    end
    
    # frozen_string_literal: true
    # Generates warehouse messages describing a PacBio run.
    # PacBio runs are approximated by {Batch batches}
    class Api::Messages::PacBioRunIO < Api::Base
      renders_model(::Batch)
    
      map_attribute_to_json_attribute(:id, 'pac_bio_run_id')
      map_attribute_to_json_attribute(:id_dup, 'pac_bio_run_name')
      map_attribute_to_json_attribute(:uuid, 'pac_bio_run_uuid')
    
      map_attribute_to_json_attribute(:updated_at)
    
      with_association(:first_output_plate) do
        map_attribute_to_json_attribute(:human_barcode, 'plate_barcode')
        map_attribute_to_json_attribute(:uuid, 'plate_uuid_lims')
    
        with_nested_has_many_association(:wells_in_column_order, as: 'wells') do
          map_attribute_to_json_attribute(:map_description, 'well_label')
          map_attribute_to_json_attribute(:uuid, 'well_uuid_lims')
    
          with_nested_has_many_association(:most_recent_active_requests_as_target_group_by_same_source, as: 'samples') do
            with_association(:initial_project) { map_attribute_to_json_attribute(:project_cost_code_for_uwh, 'cost_code') }
    
            with_association(:initial_study) { map_attribute_to_json_attribute(:uuid, 'study_uuid') }
    
            with_association(:asset) do
              map_attribute_to_json_attribute(:external_identifier, 'pac_bio_library_tube_id_lims')
              map_attribute_to_json_attribute(:uuid, 'pac_bio_library_tube_uuid')
    
              with_association(:labware) { map_attribute_to_json_attribute(:name, 'pac_bio_library_tube_name') }
    
              map_attribute_to_json_attribute(:id, 'pac_bio_library_tube_legacy_id')
    
              with_association(:primary_aliquot) do
                with_association(:sample) { map_attribute_to_json_attribute(:uuid, 'sample_uuid') }
    
                with_association(:tag) do
                  map_attribute_to_json_attribute(:oligo, 'tag_sequence')
                  map_attribute_to_json_attribute(:tag_group_id, 'tag_set_id_lims')
                  map_attribute_to_json_attribute(:map_id, 'tag_identifier')
    
                  with_association(:tag_group) { map_attribute_to_json_attribute(:name, 'tag_set_name') }
                end
              end
            end
          end
        end
      end
    end
    

    #list_of_runs = [10056,10126,10138,10344,10502,13503,13791,13845,13846,13892,13946,14104,14202,14203,14282,14338,14401,14507,15065,15070,15076,15328,15349,15358,15506,15519,15546,15563,15597,15605,15799,15804,15834,16195,16200,16233,16292,16339,16549,16574,16624,16740,16829,17008,17052,17165,17561,18717,18731,19385,20495,21728,25860,25932,26035,26499,26620,26638,27294,27356,28237,28359,28400,28489,28562,28589,28613,28626,28681,28745,29062,29086,29116,29183,30058,30066,30172,30371,30450,30516,30532,30572,31108,31240,31701,31908,31911,32018,32068,32076,32169,32224,32274,32294,32334,32542,32583,32669,32685,32956,33029,33119,33157,33218,33266,33320,33367,33384,33397,33416,33450,33467,33574,33628,33655,33670,33746,33821,33841,33883,33962,34271,34386,34387,34410,34424,34463,34534,34576,34692,34806,34830,34992,35054,35086,35168,35226,35292,35332,35522,35605,35620,35716,35786,35796,35807,35860,36149,36184,36419,36590,36648,36849,36938,36974,37027,37173,37196,58882,77232,90227,90228,90259,90393,90404,90405,90449,90596,90633,90635,90770,9990,9992,9993]
    list_of_runs = [70489, 99999]

    Messenger.where(template: "PacBioRunIO", target_id: list_of_runs).each do |messenger|
      messenger.save
    end
  end
end



