class AddPulldownPlatePurposesAndRelationships < ActiveRecord::Migration
  PLATE_PURPOSE_FLOWS = [
    [
      'WGS stock plate',
      'WGS fragmentation plate',
      'WGS fragment purification plate',
      'WGS library preparation plate',
      'WGS library plate',
      'WGS library PCR plate',
      'WGS amplified library plate',
      'WGS pooled amplified library plate'
    ], [
      'SC stock plate',
      'SC fragmentation plate',
      'SC fragment purification plate',
      'SC library preparation plate',
      'SC library plate',
      'SC library PCR plate',
      'SC amplified library plate',
      'SC hybridisation plate',
      'SC captured library plate',
      'SC captured library PCR plate',
      'SC amplified captured library plate',
      'SC pooled captured library plate'
    ], [
      'ISC stock plate',
      'ISC fragmentation plate',
      'ISC fragment purification plate',
      'ISC library preparation plate',
      'ISC library plate',
      'ISC library PCR plate',
      'ISC amplified library plate',
      'ISC pooled amplified library plate',
      'ISC hybridisation plate',
      'ISC captured library plate',
      'ISC captured library PCR plate',
      'ISC amplified captured library plate',
      'ISC pooled captured library plate'
    ]
  ]

  PLATE_PURPOSE_LEADING_TO_QC_PLATES = [
    'WGS fragment purification plate',
    'WGS library preparation plate',
    'WGS amplified library plate',

    'SC fragment purification plate',
    'SC library preparation plate',
    'SC amplified library plate',
    'SC amplified captured library plate',

    'ISC fragment purification plate',
    'ISC library preparation plate',
    'ISC amplified library plate',
    'ISC amplified captured library plate'
  ]

  def self.up
    ActiveRecord::Base.transaction do
      PLATE_PURPOSE_FLOWS.each do |flow|
        # We're using a different plate purpose for each pipeline, which means we need to attach that plate purpose to the request
        # type for it.  Then in the cherrypicking they'll only be able to pick the correct type from the list.
        stock_plate_purpose = PlatePurpose.create!(:name => flow.shift, :default_state => 'passed', :can_be_considered_a_stock_plate => true)
        pipeline_name       = /^([^\s]+)/.match(stock_plate_purpose.name)[1]  # Hack but works!
        request_type        = RequestType.find_by_name("Pulldown #{pipeline_name}") or raise StandardError, "Cannot find pulldown pipeline for #{pipeline_name}"
        request_type.acceptable_plate_purposes << stock_plate_purpose

        # Now we can build from the stock plate through to the end
        initial_purpose = stock_plate_purpose.child_plate_purposes.create!(:type => 'InitialPulldownPlatePurpose', :name => flow.shift)
        flow.inject(initial_purpose) do |parent, child_plate_name|
          parent.child_plate_purposes.create!(:name => child_plate_name)
        end
      end

      qc_plate_purpose = PlatePurpose.create!(:name => 'Pulldown QC plate')

      PLATE_PURPOSE_LEADING_TO_QC_PLATES.each do |name|
        plate_purpose = PlatePurpose.find_by_name(name) or raise StandardError, "Cannot find plate purpose #{name.inspect}"
        plate_purpose.child_plate_purposes << qc_plate_purpose
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      PlatePurpose.destroy_all([ 'name IN (?)', PLATE_PURPOSE_FLOWS.flatten + [ 'Pulldown QC plate' ] ])
    end
  end
end
