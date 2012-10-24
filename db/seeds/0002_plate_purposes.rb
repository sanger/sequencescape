ActiveRecord::Base.transaction do
  # And here is pulldown
  Pulldown::PlatePurposes::PLATE_PURPOSE_FLOWS.each do |flow|
    # We're using a different plate purpose for each pipeline, which means we need to attach that plate purpose to the request
    # type for it.  Then in the cherrypicking they'll only be able to pick the correct type from the list.
    stock_plate_purpose = Pulldown::StockPlatePurpose.create!(
      :name                            => flow.shift,
      :default_state                   => 'passed',
      :can_be_considered_a_stock_plate => true,
      :cherrypick_filters              => [
        'Cherrypick::Strategy::Filter::ByOverflow',
        'Cherrypick::Strategy::Filter::ByEmptySpaceUsage',
        'Cherrypick::Strategy::Filter::BestFit',
        'Cherrypick::Strategy::Filter::BySpecies'
      ]
    )
    pipeline_name       = /^([^\s]+)/.match(stock_plate_purpose.name)[1]  # Hack but works!
    request_type        = RequestType.find_by_name("Pulldown #{pipeline_name}") or raise StandardError, "Cannot find pulldown pipeline for #{pipeline_name}"
    request_type.acceptable_plate_purposes << stock_plate_purpose

    # Now we can build from the stock plate through to the end
    initial_purpose = Pulldown::InitialPlatePurpose.create!(
      :name                  => flow.shift,
      :cherrypickable_target => false
    ).tap do |plate_purpose|
      stock_plate_purpose.child_relationships.create!(:child => plate_purpose, :transfer_request_type => RequestType.transfer)
    end
    final_purpose = flow.inject(initial_purpose) do |parent, child_plate_name|
      options = { :name => child_plate_name, :cherrypickable_target => false }
      options[:type] = 'Pulldown::LibraryPlatePurpose' if child_plate_name =~ /^(WGS|SC|ISC) library plate$/
      PlatePurpose.create!(options).tap do |plate_purpose|
        parent.child_relationships.create!(:child => plate_purpose, :transfer_request_type => RequestType.transfer)
      end
    end

    # Ensure that the transfer to the tube at the end is possible
    tube_purpose = Tube::Purpose.find_by_name('Standard MX') or raise "Cannot find standard MX tube purpose"
    final_purpose.child_relationships.create!(:child => tube_purpose, :transfer_request_type => RequestType.transfer)
  end

  qc_plate_purpose = PlatePurpose.create!(:name => 'Pulldown QC plate', :cherrypickable_target => false)

  Pulldown::PlatePurposes::PLATE_PURPOSE_LEADING_TO_QC_PLATES.each do |name|
    plate_purpose = PlatePurpose.find_by_name(name) or raise StandardError, "Cannot find plate purpose #{name.inspect}"
    plate_purpose.child_relationships.create!(:child => qc_plate_purpose, :transfer_request_type => RequestType.transfer)
  end
end
