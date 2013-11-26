class ExistingPacbioTakesPlates < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      RequestType.find_by_name('PacBio Sample Prep').update_attributes!(
        :name => 'PacBio Library Prep',
        :asset_type => 'Well'
      )
      Pipeline.find_by_name('PacBio Sample Prep').update_attributes!(
        :name => 'PacBio Library Prep',
        :max_size => 96,
        :group_by_parent => true
      )
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      RequestType.find_by_name('PacBio Library Prep').update_attributes!(
        :name => 'PacBio Sample Prep',
        :asset_type => 'SampleTube'
      )
      Pipeline.find_by_name('PacBio Library Prep').update_attributes!(
        :name => 'PacBio Sample Prep',
        :max_size => nil,
        :group_by_parent => nil
      )
    end
  end
end
