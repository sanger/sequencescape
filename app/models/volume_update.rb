# Performs a change of volume on a resource
# Primarily created on plates via Assets Audits application to indicate reduced
# volume on, eg. working dilution creation.
# No records exist on 29/05/2019 due to no volumes configured for processes
class VolumeUpdate < ApplicationRecord
  include Uuid::Uuidable

  validates_presence_of :created_by

  # This is the target asset for which to update the state
  belongs_to :target, class_name: 'Labware', foreign_key: :target_id
  validates_presence_of :target

  validates_presence_of :volume_change

  after_create :update_volume_change_of_target
  def update_volume_change_of_target
    # So we can modify any asset's volume
    target.update_volume(volume_change)
  end
  private :update_volume_change_of_target
end
