class AddPulldownPlatePurposesAndRelationships < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      Pipeline::Pulldown::PLATE_PURPOSE_FLOWS.each do |flow|
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

      Pipeline::Pulldown::PLATE_PURPOSE_LEADING_TO_QC_PLATES.each do |name|
        plate_purpose = PlatePurpose.find_by_name(name) or raise StandardError, "Cannot find plate purpose #{name.inspect}"
        plate_purpose.child_plate_purposes << qc_plate_purpose
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      PlatePurpose.destroy_all([
        'name IN (?)',
        Pipeline::Pulldown::PLATE_PURPOSE_FLOWS.flatten + [ 'Pulldown QC plate' ]
      ])
    end
  end
end
