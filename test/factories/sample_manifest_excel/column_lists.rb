FactoryGirl.define do
  factory :column_list, class: SampleManifestExcel::ColumnList do
    initialize_with { new(build_list(:column, 5)) }

    factory :column_list_with_sanger_sample_id do
      initialize_with { new(build_list(:column, 5).push(build(:sanger_sample_id_column))) }
    end

    factory :column_list_for_plate do
      initialize_with {
        new(build_list(:column, 5)
                          .push(build(:sanger_sample_id_column))
                          .push(build(:sanger_plate_id_column))
                          .push(build(:well_column))
                          .push(build(:donor_id_column)))
      }
    end

    factory :column_list_for_tube do
      initialize_with {
        new(build_list(:column, 5)
                          .push(build(:sanger_sample_id_column))
                          .push(build(:sanger_tube_id_column))
                          .push(build(:donor_id2_column)))
      }
    end

    factory :column_list_for_multiplexed_library_tube do
       initialize_with {
         new(build_list(:column, 5)
                          .push(build(:sanger_sample_id_column))
                          .push(build(:sanger_tube_id_column))
                          .push(build(:tag_group_column))
                          .push(build(:tag_index_column))
                          .push(build(:tag2_group_column))
                          .push(build(:tag2_index_column))
                          .push(build(:library_type_column))
                          .push(build(:insert_size_from_column))
                          .push(build(:insert_size_to_column)))
       }
    end

    skip_create
  end
end
