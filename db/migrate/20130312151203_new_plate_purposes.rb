class NewPlatePurposes < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      IlluminaB::PlatePurposes.create_plate_flow(new_flow)
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      new_flow.each do |purpose|
        Purpose.find_by_name(purpose).destroy
      end
    end
  end

  def self.new_flow
    [
      'Cherrypicked',
      'Covaris',
      'Post Shear',
      'AL Libs',
      'Lib PCR',
      'Lib PCRR',
      'Lib PCR-XP',
      'Lib PCRR-XP'
    ]
  end
end
