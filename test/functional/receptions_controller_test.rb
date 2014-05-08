require "test_helper"
class ReceptionsControllerTest < ActionController::TestCase
  def self.view_page_with_no_updates
    should_respond_with :success
    should_change("Asset.count", :by => 0) { Asset.count }
  end

  context "Sample Reception" do
    setup do
      @controller = ReceptionsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
      @user = Factory :user
      @controller.stubs(:current_user).returns(@user)
      @plate = Factory :plate
      @sample_tube = Factory :sample_tube
      @location = Factory :location
    end

    should_require_login

    context "#import_from_snp" do
      context "with 1 plate" do
        setup do
          post :import_from_snp, :snp_plates => {"1" => "1234"}, :asset => {:location_id => @location.id}
        end
        should_change("Plate.count", :by => 1) { Plate.count }
        should_respond_with :redirect
        should_set_the_flash_to /queued to be imported/
      end

      context "with 3 plates" do
        setup do
          post :import_from_snp, :snp_plates => {"1" => "1234", "5"=> "7654", "10"=> "3456"}, :asset => {:location_id => @location.id}
        end
        should_change("Plate.count", :by => 3) { Plate.count }
        should_respond_with :redirect
        should_set_the_flash_to /queued to be imported/
      end

      context "with 3 plates plus blanks" do
        setup do
          post :import_from_snp, :snp_plates => {"1" => "1234", "7" => "", "5"=> "7654", "2" => "", "10"=> "3456"}, :asset => {:location_id => @location.id}
        end
        should_change("Plate.count", :by => 3) { Plate.count }
        should_respond_with :redirect
        should_set_the_flash_to /queued to be imported/
      end
    end

    context "#confirm reception" do
      context "where asset exists" do
        setup do
          post :confirm_reception, :asset_id => @plate.id, :asset => { :location_id => @location.id }
        end
        should_change("Asset.count", :by => 0) { Asset.count }
        should_respond_with :success
      end
      context "where asset doesnt exist" do
        setup do
          post :confirm_reception, :asset_id => 999999, :asset => { :location_id => @location.id }
        end
        should_change("Asset.count", :by => 0) { Asset.count }
        should_set_the_flash_to /not found/
      end

      context "create an event" do
        setup do
          post :confirm_reception, :asset_id => @sample_tube.id, :asset => { :location_id => @location.id }
        end
        should_change("Event.count", :by => 0) { Event.count }
        should_respond_with :success
      end
    end

    ["index","snp_import"].each do |controller_method|
      context "##{controller_method}" do
        setup do
          get controller_method, :id => @plate.id
        end
        view_page_with_no_updates
      end
    end

  end

end
