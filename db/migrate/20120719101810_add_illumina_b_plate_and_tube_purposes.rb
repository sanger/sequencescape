class AddIlluminaBPlateAndTubePurposes < ActiveRecord::Migration
  def self.up
    do_it(:create)
  end

  def self.down
    do_it(:destroy)
  end

  def self.do_it(action)
    ActiveRecord::Base.transaction do
      IlluminaB::PlatePurposes.send(:"#{action}_tube_purposes")
      IlluminaB::PlatePurposes.send(:"#{action}_plate_purposes")
      IlluminaB::PlatePurposes.send(:"#{action}_branches")
    end
  end
end
