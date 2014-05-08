class AssetsController < ApplicationController

  class PlateLayout
    DEFAULT_WELL = { :request => nil, :asset => nil, :error => nil }

    attr_reader :width, :height, :wells

    def initialize(width, height)
      @width, @height = width, height
      @wells = (1..@width*@height).map { |_| DEFAULT_WELL.dup }
    end

    def set_details_for_well_at(location_id, details)
      assert_valid_location(location_id)
      @wells[ location_id-1 ] = details
    end

    def size
      @width * @height
    end

    def cell_name_for_well_at(row, column)
      Map.find_by_location_id_and_asset_size(((row * self.width) + column +1 ), self.size).description
    end

    def location_for_well_at(row, column)
      ((row * @width) + column) + 1
    end

    def well_at(row, column)
      location_id = location_for_well_at(row, column)
      assert_valid_location(location_id)
      @wells[ location_id-1 ]
    end

    def empty_well_at?(row, column)
      DEFAULT_WELL == well_at(row, column)
    end

    def good_well_at?(row, column)
      well = well_at(row, column)
      [:request, :asset].all? { |field| not well[ field ].nil? }
    end

    def bad_well_at?(row, column)
      well = well_at(row, column)
      not well[:error].nil?
    end

    def assert_valid_location(location_id)
      raise StandardError, "Location out of bounds" unless (1..self.size).include?(location_id)
    end
  end

end

