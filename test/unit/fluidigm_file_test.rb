# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2013,2015,2016 Genome Research Ltd.

require 'test_helper'
require 'csv'

class FluidigmFileTest < ActiveSupport::TestCase
  XY = 'M'
  XX = 'F'
  YY = 'F'
  NC = 'Unknown'

  context 'A fluidigm file' do
    setup do
      File.open("#{Rails.root}/test/data/fluidigm.csv") do |file|
        @fluidigm = FluidigmFile.new(file.read)
      end

      @well_maps = {
        'S06' => {
          markers: [XY, XY, XY],
          count: 94
        },
        'S04' => {
          markers: [NC, XX, XX],
          count: 92
        },
        'S43' => {
          markers: [XX, XX, XX],
          count: 94
        }
      }
    end

    should 'validate plate' do
      assert  @fluidigm.for_plate?('1381832088')
      assert !@fluidigm.for_plate?('1381832089')
    end

    should 'find 95 wells' do
      count = 0
      @fluidigm.each_well do |_well|
        count += 1
      end
      assert_equal 95, count
    end

    should 'provide an interface for wells' do
      checked = 0
      @fluidigm.each_well do |well|
        assert well.description != 'S96'
        next if @well_maps[well.description].nil?
        assert_equal @well_maps[well.description][:markers].sort, well.gender_markers.sort
        assert_equal @well_maps[well.description][:count], well.count
        checked += 1
      end
      assert_equal @well_maps.size, checked
    end

    should 'let us grab all well locations' do
      assert_equal 95, @fluidigm.well_locations.count
      @fluidigm.well_locations.each { |l| assert l.is_a?(String) }
    end

    should 'let us fetch individual wells' do
      @well_maps.each do |loc, _properties|
        well = @fluidigm.well_at(loc)
        assert well.is_a?(FluidigmFile::FluidigmWell)
        assert_equal loc, well.description
        assert_equal @well_maps[loc][:markers].sort, well.gender_markers.sort
        assert_equal @well_maps[loc][:count], well.count
      end
    end
  end
end
