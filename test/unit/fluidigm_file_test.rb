# frozen_string_literal: true

require 'test_helper'
require 'csv'

class FluidigmFileTest < ActiveSupport::TestCase
  XY = 'M'
  XX = 'F'
  YY = 'F'
  NC = 'U'

  context 'A fluidigm file' do
    setup do
      File.open("#{Rails.root}/test/data/fluidigm.csv") { |file| @fluidigm = FluidigmFile.new(file.read) }

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
      assert @fluidigm.for_plate?('1381832088')
      assert_not @fluidigm.for_plate?('1381832089')
    end

    should 'find 95 wells' do
      count = 0
      @fluidigm.each_well { |_well| count += 1 }

      assert_equal 95, count
    end

    should 'provide an interface for wells' do
      checked = 0
      @fluidigm.each_well do |well|
        assert_not_equal well.description, 'S96'
        next if @well_maps[well.description].nil?

        assert_equal @well_maps[well.description][:markers].sort, well.gender_markers.sort
        assert_equal @well_maps[well.description][:count], well.count
        checked += 1
      end

      assert_equal @well_maps.size, checked
    end

    should 'let us grab all well locations' do
      assert_equal 95, @fluidigm.well_locations.count
      @fluidigm.well_locations.each { |l| assert_kind_of String, l }
    end

    should 'let us fetch individual wells' do
      @well_maps.each do |loc, _properties|
        well = @fluidigm.well_at(loc)

        assert_kind_of FluidigmFile::FluidigmWell, well
        assert_equal loc, well.description
        assert_equal @well_maps[loc][:markers].sort, well.gender_markers.sort
        assert_equal @well_maps[loc][:count], well.count
      end
    end
  end
end
