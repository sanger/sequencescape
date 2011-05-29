class AddPulldownPlatePurposesAndRelationships < ActiveRecord::Migration
  PLATE_PURPOSE_FLOWS = [
    [
      'WGS fragmentation plate',
      'WGS fragment purification plate',
      'WGS library preparation plate',
      'WGS library plate',
      'WGS library PCR plate',
      'WGS amplified library plate',
      'WGS pooled amplified library plate'
    ], [
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
      # We have to have a special stock plate purpose for the pulldown pipeline to prevent it clashing with the SLF
      # stock plates (where they just create all of the children).  Really we should be binding the plate purpose
      # to the pipeline it is targeted for, but this is a compromise for the moment.
      stock_plate_purpose = PlatePurpose.create!(:name => 'Pulldown stock plate')

      PLATE_PURPOSE_FLOWS.each do |flow|
        flow.inject(stock_plate_purpose) do |parent, child_plate_name|
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
