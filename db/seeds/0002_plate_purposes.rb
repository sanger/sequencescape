# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2012,2013,2014,2015 Genome Research Ltd.

ActiveRecord::Base.transaction do
  # And here is pulldown
  purpose_flows = Pulldown::PlatePurposes::PLATE_PURPOSE_FLOWS.clone
  purpose_flows.pop
  purpose_flows.each do |flow_o|
    flow = flow_o.clone
    # We're using a different plate purpose for each pipeline, which means we need to attach that plate purpose to the request
    # type for it.  Then in the cherrypicking they'll only be able to pick the correct type from the list.
    stock_plate_purpose = PlatePurpose::Input.create!(
      name: flow.shift,
      default_state: 'passed',
      stock_plate: true,
      cherrypick_filters: [
        'Cherrypick::Strategy::Filter::ByOverflow',
        'Cherrypick::Strategy::Filter::ByEmptySpaceUsage',
        'Cherrypick::Strategy::Filter::BestFit',
        'Cherrypick::Strategy::Filter::BySpecies'
      ]
    )
    pipeline_name       = /^([^\s]+)/.match(stock_plate_purpose.name)[1] # Hack but works!
    request_type        = RequestType.find_by(name: "Illumina-A Pulldown #{pipeline_name}") or raise StandardError, "Cannot find pulldown pipeline for #{pipeline_name}"
    request_type.acceptable_plate_purposes << stock_plate_purpose

    # Now we can build from the stock plate through to the end
    Pulldown::InitialPlatePurpose.create!(
      name: flow.shift,
      cherrypickable_target: false
    )

    flow.each do |child_plate_name|
      options = { name: child_plate_name, cherrypickable_target: false }
      options[:type] = 'Pulldown::LibraryPlatePurpose' if child_plate_name.match?(/^(WGS|SC|ISC) library plate$/)
      PlatePurpose.create!(options)
    end
  end

  PlatePurpose.create!(name: 'Pulldown QC plate', cherrypickable_target: false)

  PlatePurpose.create!(
    name: 'Pre-capture stock',
    target_type: 'Plate',
    stock_plate: true,
    barcode_printer_type: BarcodePrinterType.find_by(name: '96 Well Plate')
  )
end
