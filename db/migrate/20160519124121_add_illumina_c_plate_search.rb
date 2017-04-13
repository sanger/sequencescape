class AddIlluminaCPlateSearch < ActiveRecord::Migration
  def up
    plate_purposes = Purpose.where(name: ['ILC Stock',
      'ILC AL Libs',
      'ILC Lib PCR',
      'ILC Lib PCR-XP',
      'ILC AL Libs Tagged']).pluck(:id)
    Search::FindPlatesForUser.create!(name: 'Find Illumina-C plates for user', default_parameters: { plate_purpose_ids: plate_purposes, limit: 30, include_used: true })
  end

  def down
    Search::FindPlatesForUser.where(name: 'Find Illumina-C plates for user').first!.destroy
  end
end
