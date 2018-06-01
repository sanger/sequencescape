require './lib/request_class_deprecator'

class RemovePrepcrToPcr < ActiveRecord::Migration
  include RequestClassDeprecator

  def up
    ActiveRecord::Base.transaction do
      deprecate_class('IlluminaB::Requests::PrePcrToPcr', state_change: { 'started_fx' => 'started', 'started_mj' => 'passed' })
      deprecate_class('IlluminaHtp::Requests::PrePcrToPcr', state_change: { 'started_fx' => 'started', 'started_mj' => 'passed' })
    end
  end

  def down
  end
end
