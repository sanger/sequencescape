ActiveRecord::Base.transaction do
  # And here is pulldown
  Pulldown::PlatePurposes::PLATE_PURPOSE_FLOWS.each do |flow|
    # We're using a different plate purpose for each pipeline, which means we need to attach that plate purpose to the request
    # type for it.  Then in the cherrypicking they'll only be able to pick the correct type from the list.
    stock_plate_purpose = Pulldown::StockPlatePurpose.create!(:name => flow.shift, :default_state => 'passed', :can_be_considered_a_stock_plate => true)
    pipeline_name       = /^([^\s]+)/.match(stock_plate_purpose.name)[1]  # Hack but works!
    request_type        = RequestType.find_by_name("Pulldown #{pipeline_name}") or raise StandardError, "Cannot find pulldown pipeline for #{pipeline_name}"
    request_type.acceptable_plate_purposes << stock_plate_purpose

    # Now we can build from the stock plate through to the end
    initial_purpose = Pulldown::InitialPlatePurpose.create!(:name => flow.shift).tap do |plate_purpose|
      stock_plate_purpose.child_relationships.create!(:child => plate_purpose, :transfer_request_type => RequestType.transfer)
    end
    flow.inject(initial_purpose) do |parent, child_plate_name|
      options = { :name => child_plate_name, :cherrypickable_target => false }
      options[:type] = 'Pulldown::LibraryPlatePurpose' if child_plate_name =~ /^(WGS|SC|ISC) library plate$/
      PlatePurpose.create!(options).tap do |plate_purpose|
        parent.child_relationships.create!(:child => plate_purpose, :transfer_request_type => RequestType.transfer)
      end
    end
  end

  qc_plate_purpose = PlatePurpose.create!(:name => 'Pulldown QC plate')

  Pulldown::PlatePurposes::PLATE_PURPOSE_LEADING_TO_QC_PLATES.each do |name|
    plate_purpose = PlatePurpose.find_by_name(name) or raise StandardError, "Cannot find plate purpose #{name.inspect}"
    plate_purpose.child_relationships.create!(:child => qc_plate_purpose, :transfer_request_type => RequestType.transfer)
  end

  # We only have one flow at the moment
  IlluminaB::PlatePurposes.create_plate_purposes
end
