FactoryGirl.define do


  factory :range_list, class: SampleManifestExcel::RangeList do


  	r = YAML::load_file(File.expand_path(File.join(Rails.root,"test","data", "sample_manifest_excel","sample_manifest_validation_ranges.yml")))

  	initialize_with { new(r) }

  	factory :range_list_with_absolute_reference do
    	after(:build)  do |range_list|
    		worksheet = build :axlsx_worksheet
    		range_list.set_absolute_references(worksheet.name)
    	end
    end

  end

end