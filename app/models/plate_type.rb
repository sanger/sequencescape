# frozen_string_literal: true
class PlateType < ApplicationRecord # rubocop:todo Style/Documentation
  validates :name, :maximum_volume, presence: true

  class << self
    def plate_default_type
      create_with(maximum_volume: Sequencescape::Application.config.plate_default_max_volume).find_or_create_by!(
        name: Sequencescape::Application.config.plate_default_type
      )
    end

    def cherrypickable_default_type
      Sequencescape::Application.config.cherrypickable_default_type
    end

    def names_and_maximum_volumes
      PlateType.all.map { |pt| "#{pt.name}: #{pt.maximum_volume}" }.join(', ')
    end
  end
end
