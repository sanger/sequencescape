require "test_helper"

class FluidigmFileTest < ActiveSupport::TestCase

  XY = 'M'
  XX = 'F'
  YY = 'F'
  NC = 'Unknown'

  context "A fluidigm file" do

    setup do
      @file = File.open("#{RAILS_ROOT}/test/data/fluidigm.csv")
      @fluidigm = FluidigmFile.new(@file.read)
      @well_maps = {
        'S06' => {
          :markers => [ XY,XY,XY ],
          :count   => 94
        },
        'S04' => {
          :markers=> [ NC, XX, XX ],
          :count=>   92
        },
        'S43' => {
          :markers=> [ XX, XX, XX ],
          :count=>   94
        }
      }
    end

    should "validate plate" do
      assert  @fluidigm.for_plate?('1381832088')
      assert !@fluidigm.for_plate?('1381832089')
    end

    should "find 95 wells" do
      count = 0
      @fluidigm.each_well do |well|
        count += 1
      end
      assert_equal 95, count
    end

    should "provide an interface for wells" do
      checked = 0
      @fluidigm.each_well do |well|
        assert well.description != 'S96'
        next if @well_maps[well.description].nil?
        assert_equal @well_maps[well.description][:markers].sort, well.gender_markers.sort
        assert_equal @well_maps[well.description][:count], well.count
        checked+=1
      end
      assert_equal @well_maps.size, checked
    end

  end

end
