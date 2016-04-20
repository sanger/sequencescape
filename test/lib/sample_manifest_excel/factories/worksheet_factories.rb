FactoryGirl.define do

  factory :worksheet, class: Axlsx::Worksheet do

  	workbook Axlsx::Package.new.workbook
  	name 'New worksheet'

  	initialize_with { new(workbook, name: name) }

  end

end