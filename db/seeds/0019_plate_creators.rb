ActiveRecord::Base.transaction do

  excluded = ['Dilution Plates']

  PlatePurpose.find_all_by_qc_display(true).each do |plate_purpose|
    Plate::Creator.create!(:plate_purpose => plate_purpose, :name => plate_purpose.name).tap do |creator|
      creator.plate_purposes = plate_purpose.child_plate_purposes
    end unless excluded.include?(plate_purpose.name)
  end

  # Additional plate purposes required
  [ 'Pico dilution', 'Working dilution' ].each do |name|
    plate_purpose = PlatePurpose.find_by_name(name) or raise StandardError, "Cannot find #{name.inspect} plate purpose"
    Plate::Creator.create!(:name => name, :plate_purpose => plate_purpose, :plate_purposes => [ plate_purpose ])
  end
end
