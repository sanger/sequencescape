class NewTubePurposes < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      IlluminaB::PlatePurposes.create_tube_flow(new_flow)
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
      'Lib Pool',
      'Lib Pool Norm',
      'Lib Pool Conc',
      'Lib Pool SS',
      'Lib Pool SS-XP',
      'Lib Pool SS-XP-Norm'
    ]
  end
end
