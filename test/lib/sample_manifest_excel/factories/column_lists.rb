FactoryGirl.define do

  factory :column_list, class: SampleManifestExcel::ColumnList do

    initialize_with { new(build_list(:column, 5)) }

  end

end