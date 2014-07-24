require "test_helper"

class WellTest < ActiveSupport::TestCase
  context "A well" do
    setup do
      @well = Factory :well
    end

    context "with gender_markers results" do
      setup do
        @well.well_attribute.update_attributes!(:gender_markers => ['M','F','F'])
      end
      should "create an event if nothings changed and there are no previous events" do
        @well.update_gender_markers!(['M','F','F'], 'SNP')
        assert_equal 1, @well.events.count
      end

      should "an event for each resource if nothings changed" do
        @well.update_gender_markers!(['M','F','F'], 'MSPEC')
        assert_equal 1, @well.events.count
        assert 'MSPEC', @well.events.last.content
        @well.update_gender_markers!(['M','F','F'], 'SNP')
        assert_equal 2, @well.events.count
        assert 'SNP', @well.events.last.content
      end

      should "only 1 event if nothings changed for the same resource" do
        @well.update_gender_markers!(['M','F','F'], 'SNP')
        assert_equal 1, @well.events.count
        assert 'SNP', @well.events.last.content
        @well.update_gender_markers!(['M','F','F'], 'SNP')
        assert_equal 1, @well.events.count
        assert 'SNP', @well.events.last.content
      end
    end

    context "without gender_markers results" do
      should "an event for each resource if its changed" do
        @well.update_gender_markers!(['M','F','F'], 'MSPEC')
        assert_equal 1, @well.events.count
        assert 'MSPEC', @well.events.last.content
        @well.update_gender_markers!(['M','F','F'], 'SNP')
        assert_equal 2, @well.events.count
        assert 'SNP', @well.events.last.content
      end
    end

    context "with sequenom_count results" do
      setup do
         @well.well_attribute.update_attributes!(:sequenom_count => 5)
      end

      should "add an event if its changed" do
        @well.update_sequenom_count!(10, 'MSPEC')
        assert_equal 1, @well.events.count
        assert 'MSPEC', @well.events.last.content
        @well.update_sequenom_count!(10, 'SNP')
        assert_equal 1, @well.events.count
        assert 'MSPEC', @well.events.last.content
      end
    end

    context "without sequenom_count results" do
      should "add an event if its changed" do
        @well.update_sequenom_count!(10, 'MSPEC')
        assert_equal 1, @well.events.count
        assert 'MSPEC', @well.events.last.content
        @well.update_sequenom_count!(11, 'SNP')
        assert_equal 2, @well.events.count
        assert 'SNP', @well.events.last.content
      end
    end

    should "have pico pass" do
      @well.well_attribute.pico_pass = "Yes"
      assert_equal "Yes", @well.get_pico_pass
    end

    should "have gel pass" do
      @well.well_attribute.gel_pass = "Pass"
      assert_equal "Pass", @well.get_gel_pass
      assert @well.get_gel_pass.is_a?(String)
    end

    should "have picked volume" do
      @well.set_picked_volume(3.6)
      assert_equal 3.6, @well.get_picked_volume
    end

    should "allow concentration to be set" do
      @well.set_concentration(1.0)
      concentration = @well.get_concentration
      assert_equal 1.0, concentration
      assert concentration.is_a?(Float)
    end

    should "allow volume to be set" do
      @well.set_current_volume(2.5)
      vol = @well.get_volume
      assert_equal 2.5, vol
      assert vol.is_a?(Float)
    end

    should "allow current volume to be set" do
      @well.set_current_volume(3.5)
      vol = @well.get_current_volume
      assert_equal 3.5, vol
      assert vol.is_a?(Float)
    end

    should "allow buffer volume to be set" do
      @well.set_buffer_volume(4.5)
      vol = @well.get_buffer_volume
      assert_equal 4.5, vol
      assert vol.is_a?(Float)
    end

    context "with a plate" do
      setup do
        @plate = Factory :plate
        @plate.add_and_save_well @well
      end
      should "have a parent plate" do
        parent = @well.plate
        assert parent.is_a?(Plate)
        assert_equal parent.id,@plate.id
      end

      context "for a tecan" do
        context "with valid inputs" do
          setup do
            @well.map = Map.first
          end
          should "return true" do
            assert !@well.map.nil?
            assert @well.valid_well_on_plate
          end
        end

        context "with nil parameters" do
          setup do
            @well_nil = Well.new
          end
          should "return false" do
            assert_equal false, @well_nil.valid_well_on_plate
          end
        end
      end
    end

    [
     [1000 , 10  , 50, 50, 0],
     [1000 , 10  , 10, 10, 0],
     [100  , 100 , 50, 1 , 9],
     [1000 , 1000, 50, 1 , 9],
     [5000 , 1000, 50, 5 , 5],
     [10   , 100 , 50, 1 , 9],
     [1000 , 250 , 50, 4 , 6],
     [10000, 250 , 50, 40, 0],
     [10000, 250 , 30, 30, 0]
    ].each do |target_ng ,  measured_concentration , measured_volume , stock_to_pick , buffer_added|
    context "cherrypick by nano grams" do
      setup do
        @source_well = Factory :well
        @target_well = Factory :well
        minimum_volume = 10
        maximum_volume = 50
        @source_well.well_attribute.update_attributes!(:concentration => measured_concentration, :measured_volume => measured_volume)
        @target_well.volume_to_cherrypick_by_nano_grams(minimum_volume, maximum_volume, target_ng, @source_well)
      end
      should "output stock_to_pick #{stock_to_pick} for a target of #{target_ng} with vol #{measured_volume} and conc #{measured_concentration}" do
          assert_equal stock_to_pick, @target_well.well_attribute.picked_volume

      end
      should "output buffer #{buffer_added} for a target of #{target_ng} with vol #{measured_volume} and conc #{measured_concentration}" do
          assert_equal buffer_added, @target_well.well_attribute.buffer_volume
      end
    end
  end


    context "to be cherrypicked" do

      context "with no source concentration" do
        should "raise an error" do
          assert_raises Cherrypick::ConcentrationError do
            @well.volume_to_cherrypick_by_nano_grams_per_micro_litre(1.1, 2.2, 0.0)
            @well.volume_to_cherrypick_by_nano_grams_per_micro_litre(1.2, 2.2, "")
          end
        end
      end

      should "return volume to pick" do
        assert_equal 2.0, @well.volume_to_cherrypick_by_nano_grams_per_micro_litre(5.0, 50.0, 200.0)
        assert_equal 4.0,  @well.volume_to_cherrypick_by_nano_grams_per_micro_litre(13.0, 30.0, 100.0)
      end

      should "set the buffer volume" do
        vol_to_pick = @well.volume_to_cherrypick_by_nano_grams_per_micro_litre(5.0, 50.0, 200.0)
        assert_equal 3.0, @well.get_buffer_volume
      end

      should "set buffer and volume_to_pick correctly" do
        vol_to_pick = @well.volume_to_cherrypick_by_nano_grams_per_micro_litre(5.0, 50.0, 200.0)
        assert_equal @well.get_picked_volume, vol_to_pick
        assert_equal 5.0, @well.get_buffer_volume + vol_to_pick
      end
    end
  end

end
