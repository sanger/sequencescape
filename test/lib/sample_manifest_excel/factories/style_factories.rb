FactoryGirl.define do

  factory :style, class: SampleManifestExcel::Style do

  	workbook Axlsx::Package.new.workbook
  	options ({locked: false})

  	initialize_with { new(workbook, options) }

  end

end