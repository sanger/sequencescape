require "test_helper"

class PlateManifestTest < ActiveSupport::TestCase
  context "#find_plates_from_samples" do
    setup do
      @manifest = Factory :sample_manifest, :count => 1
      @sample = Factory :sample
      well_without_plate = Well.create!(:sample => @sample)
      well_with_plate = Well.create!(:sample => @sample)
      @plate = Factory :plate      
      @plate.wells << well_with_plate
      @user = Factory :user
      
      
    end

    should "add an event to the plate" do
      @manifest.plates_update_events([@sample],@user)
      assert_equal 1, @plate.events.count
    end
    
  end
end
