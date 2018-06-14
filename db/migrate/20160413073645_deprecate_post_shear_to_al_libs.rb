require './lib/request_class_deprecator'

class DeprecatePostShearToAlLibs < ActiveRecord::Migration
  include RequestClassDeprecator

  def up
    ActiveRecord::Base.transaction do
      # The FX transfer state was previously triggered by the robot starting transfer out
      # of the plate. The plate was then passed by the subsequent mj_started transition
      # of the plate downstream. With the new simplified model this means that fx_transfer
      # is equivalent to a passed state.
      deprecate_class('IlluminaHtp::Requests::PostShearToAlLibs', state_change: { 'fx_transfer' => 'passed' })
    end
  end

  def down
  end
end
