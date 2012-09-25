require "test_helper"
require 'submissions_controller'

class SubmissionsControllerTest < ActionController::TestCase
  context "Submissions controller" do
    setup do
      @user = Factory :user
      @controller = SubmissionsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
      @controller.stubs(:logged_in?).returns(@user)
      @controller.stubs(:current_user).returns(@user)

      @plate = Factory :plate, :barcode => 123456
      [
        'A1','A2','A3','A4','A5','A6','A7','A8','A9','A10','A11','A12',
        'B1','B2','B3','B4','B5','B6','B7','B8','B9','B10','B11','B12',
        'C1','C2','C3'
      ].each do |location|
        well = Factory :well_with_sample_and_without_plate, :map => Map.find_by_description(location)
        @plate.wells << well
      end
      @plate.wells << Factory(:well, :map => Map.find_by_description('C5'))
      @study = Factory :study, :name => 'A study'
      @project = Factory :project, :name => 'A project'
      @submission_template = SubmissionTemplate.find_by_name('Cherrypicking for pulldown')
    end

    should_require_login

    context "by sample name" do
      #Mainly to verify that it isn't the new test that is broken

      setup do
        samples = Well.with_aliquots.each.map {|w| w.aliquots.first.sample.name}

        post(:create, :submission => {:is_a_sequencing_order=>"false", :comments=>"", :template_id=>@submission_template.id.to_s, :order_params=>{"read_length"=>"37", "fragment_size_required_to"=>"400", "bait_library_name"=>"Human all exon 50MB", "fragment_size_required_from"=>"100", "library_type"=>"Agilent Pulldown"}, :asset_group_id=>"", :study_id=>@study.id.to_s, :sample_names_text=>samples[1..4].join("\n"), :plate_purpose_id=>@plate.plate_purpose.id.to_s, :project_name=>"A project"})

      end

      should "create the appropriate orders" do
        assert_equal 4, Order.first.assets.count
      end

    end

    context "by plate barcode" do

      setup do
        post :create, plate_submission('DN123456P')
      end

      should "create the appropriate orders" do
        assert_equal 27, Order.first.assets.count
      end

    end

    context "should allow submission by plate barcode and wells" do

      setup do
        post :create, plate_submission('DN123456P:A1,B3,C2')
      end

      should "create the appropriate orders" do
        assert_equal 3, Order.first.assets.count
      end

    end

    context "should allow submission by plate barcode and rows" do

      setup do
        post :create, plate_submission('DN123456P:B,C')
      end

      should "create the appropriate orders" do
        assert_equal 15, Order.first.assets.count
      end


    end

    context "should allow submission by plate barcode and columns" do

      setup do
        post :create, plate_submission('DN123456P:1,3,5')
      end

      should "create the appropriate orders" do
        assert_equal 8, Order.first.assets.count
      end

    end

  end

  def plate_submission(text)
    {:submission => {:is_a_sequencing_order=>"false", :comments=>"", :template_id=>@submission_template.id.to_s, :order_params=>{"read_length"=>"37", "fragment_size_required_to"=>"400", "bait_library_name"=>"Human all exon 50MB", "fragment_size_required_from"=>"100", "library_type"=>"Agilent Pulldown"}, :asset_group_id=>"", :study_id=>@study.id.to_s, :sample_names_text=>'', :barcodes_wells_text => text, :plate_purpose_id=>@plate.plate_purpose.id.to_s, :project_name=>"A project"}}
  end
end
