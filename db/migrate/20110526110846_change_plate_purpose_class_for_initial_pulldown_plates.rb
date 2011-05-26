class ChangePlatePurposeClassForInitialPulldownPlates < ActiveRecord::Migration
  def self.change_to(plate_purpose_class)
    ActiveRecord::Base.transaction do
      PlatePurpose.update_all(
        %Q{type="#{plate_purpose_class}"}, [
          'name IN (?)', [
            'WGS fragmentation plate',
            'SC fragmentation plate',
            'ISC fragmentation plate'
          ]
        ]
      )
    end
  end

  def self.up
    change_to('InitialPulldownPlatePurpose')
  end

  def self.down
    change_to('PlatePurpose')
  end
end
