# frozen_string_literal: true

ActiveRecord::Base.transaction do
  # And here is pulldown
  purpose_flows = Pulldown::PlatePurposes::PLATE_PURPOSE_FLOWS.dup
  purpose_flows.pop
  purpose_flows.each do |flow_o|
    flow = flow_o.dup

    # We're using a different plate purpose for each pipeline, which means we need to attach that plate purpose to the
    # request type for it.  Then in the cherrypicking they'll only be able to pick the correct type from the list.
    stock_plate_purpose = PlatePurpose::Input.create!(name: flow.shift, default_state: 'passed', stock_plate: true)
    pipeline_name = /^([^\s]+)/.match(stock_plate_purpose.name)[1] # Hack but works!
    request_type = RequestType.find_by(name: "Illumina-A Pulldown #{pipeline_name}") or
      raise StandardError, "Cannot find pulldown pipeline for #{pipeline_name}"
    request_type.acceptable_purposes << stock_plate_purpose

    # Now we can build from the stock plate through to the end
    PlatePurpose.create!(name: flow.shift, cherrypickable_target: false)

    flow.each do |child_plate_name|
      options = { name: child_plate_name, cherrypickable_target: false }
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
