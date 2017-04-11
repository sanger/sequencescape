# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

class AssetsController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!

  class PlateLayout
    DEFAULT_WELL = { request: nil, asset: nil, error: nil }

    attr_reader :width, :height, :wells

    def initialize(width, height)
      @width, @height = width, height
      @wells = (1..@width * @height).map { |_| DEFAULT_WELL.dup }
    end

    def set_details_for_well_at(location_id, details)
      assert_valid_location(location_id)
      @wells[location_id - 1] = details
    end

    def size
      @width * @height
    end

    def cell_name_for_well_at(row, column)
      Map.find_by(location_id: ((row * width) + column + 1), asset_size: size).description
    end

    def location_for_well_at(row, column)
      ((row * @width) + column) + 1
    end

    def well_at(row, column)
      location_id = location_for_well_at(row, column)
      assert_valid_location(location_id)
      @wells[location_id - 1]
    end

    def empty_well_at?(row, column)
      DEFAULT_WELL == well_at(row, column)
    end

    def good_well_at?(row, column)
      well = well_at(row, column)
      [:request, :asset].all? { |field| not well[field].nil? }
    end

    def bad_well_at?(row, column)
      well = well_at(row, column)
      not well[:error].nil?
    end

    def assert_valid_location(location_id)
      raise StandardError, 'Location out of bounds' unless (1..size).cover?(location_id)
    end
  end
end
