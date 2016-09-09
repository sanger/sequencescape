FactoryGirl.define do

  factory :column_list, class: SampleManifestExcel::ColumnList do

    initialize_with { new(build_list(:column, 5)) }

    factory :column_list_with_sanger_sample_id do

      initialize_with { new(build_list(:column, 5).push(build(:sanger_sample_id_column))) }

    end

  end

end