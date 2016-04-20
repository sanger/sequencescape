FactoryGirl.define do

  factory :column, class: SampleManifestExcel::Column do

    heading "PUBLIC NAME"
    name :public_name

    initialize_with { new(name: name, heading: heading) }
  end

end