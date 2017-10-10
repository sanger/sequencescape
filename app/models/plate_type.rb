class PlateType < ApplicationRecord
  validates_presence_of :name, :maximum_volume

  class << self
    def cherrypickable_default_type
      Sequencescape::Application.config.cherrypickable_default_type
    end

    def names_and_maximum_volumes
      PlateType.all.map { |pt| "#{pt.name}: #{pt.maximum_volume}" }.join(', ')
    end
  end
end
