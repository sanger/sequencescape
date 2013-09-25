class AddCherrypickForFluidgmRequestTypes < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      RequestType.create!(shared_options.merge({
        :key => 'pick_to_sta',
        :name => 'Pick to STA',
        :order => 1,
        :request_class_name => 'CherrypickForPulldownRequest'
        })
      ).tap do |rt|
        rt.acceptable_plate_purposes << Purpose.find_by_name!('Working Dilution')
      end
      RequestType.create!(shared_options.merge({
        :key => 'pick_to_sta2',
        :name => 'Pick to STA2',
        :order => 2,
        :request_class_name => 'CherrypickForPulldownRequest'
        })
      ).tap do |rt|
        rt.acceptable_plate_purposes << Purpose.find_by_name!('STA')
      end
      RequestType.create!(shared_options.merge({
        :key => 'pick_to_fluidgm',
        :name => 'Pick to Fluidgm',
        :order => 3,
        :request_class_name => 'CherrypickForFluidgmRequest'
        })
      ).tap do |rt|
        rt.acceptable_plate_purposes << Purpose.find_by_name!('STA2')
      end
    end
  end

  def self.shared_options
    {
        :workflow => Submission::Workflow.find_by_name('Microarray genotyping'),
        :asset_type => 'Well',
        :target_asset_type => 'Well',
        :initial_state => 'pending'
    }
  end

  def self.down
    ActiveRecord::Base.transaction do
      RequestType.find_all_by_key(['pick_to_sta','pick_to_sta2','pick_to_fluidgm']).each(&:destroy)
    end
  end
end
