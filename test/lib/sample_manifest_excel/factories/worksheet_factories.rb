FactoryGirl.define do

  factory :worksheet, class: Axlsx::Worksheet do

  	workbook Axlsx::Package.new.workbook
  	sequence(:name) {|n| "Worksheet #{n}"}

  	initialize_with { new(workbook, name: name) }

  end

end