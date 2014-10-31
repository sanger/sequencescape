require "test_helper"

class AssetRackTest < ActiveSupport::TestCase

  context "Rack priority" do
    setup do
      @plate = Factory :transfer_plate
      user = Factory(:user)
      @plate.wells.each_with_index do |well,index|
        Factory :request, :asset=>well, :submission=>Submission.create!(:priority => index+1, :user => user)
      end
    end

    should "inherit the highest submission priority" do
      assert_equal 2, @plate.priority
    end
  end

  context "Plate submission" do
    setup do
      @rack1 = Factory :plate
      @plate2 = Factory :plate
      @plate3 = Factory :plate
      @workflow = Factory :submission_workflow,:key => 'microarray_genotyping'
      @request_type_1 = Factory :well_request_type, :workflow => @workflow
      @request_type_2 = Factory :well_request_type, :workflow => @workflow
      @workflow.request_types << @request_type_1
      @workflow.request_types << @request_type_2
      @study = Factory :study
      @project = Factory :project
      @user = Factory :user
      @current_time = Time.now

      [@rack1, @plate2,@plate3].each do |plate|
        2.times do
          plate.add_and_save_well(Well.new)
        end
      end
    end
    context "#generate_plate_submission(project, study, user, current_time)" do
      context "with valid inputs" do
        setup do
          @rack1.generate_plate_submission(@project, @study, @user, @current_time)
        end
        should_change("Event.count", :by => 1) { Event.count }
        should_change("Submission.count", :by => 1) { Submission.count }
        should_change("Request.count", :by => 0) { Request.count }
        should "not set study.errors" do
          assert_equal 0, @study.errors.count
        end
      end
    end

    context "#create_plates_submission(project, study, plates, user)" do
      context "with valid inputs" do
        context "and 1 plate" do
          setup do
            Plate.create_plates_submission(@project, @study, [@rack1], @user)
          end
          should_change("Event.count", :by => 1) { Event.count }
          should_change("Submission.count", :by => 1) { Submission.count }
          should_change("Request.count", :by => 0) { Request.count }
          should "not set study.errors" do
            assert_equal 0, @study.errors.count
          end
        end
        context "and 3 plates" do
          setup do
            Plate.create_plates_submission(@project, @study, [@rack1,@plate3,@plate2], @user)
          end
          should_change("Event.count", :by => 3) { Event.count }
          should_change("Submission.count", :by => 3) { Submission.count }
          should_change("Request.count", :by => 0) { Request.count }
          should "not set study.errors" do
            assert_equal 0, @study.errors.count
          end
        end
        context "and no plates" do
          setup do
            Plate.create_plates_submission(@project, @study, [], @user)
          end
          should_change("Event.count", :by => 0) { Event.count }
          should_change("Submission.count", :by => 0) { Submission.count }
          should "not set study.errors" do
            assert_equal 0, @study.errors.count
          end
        end
      end

      context "with invalid inputs" do
        context "where user is nil" do
          setup do
            Plate.create_plates_submission(@project, @study, [@rack1], nil)
          end
          should_change("Event.count", :by => 0) { Event.count }
          should_change("Submission.count", :by => 0) { Submission.count }
        end
        context "where project is nil" do
          setup do
            Plate.create_plates_submission(nil, @study, [@rack1], @user)
          end
          should_change("Event.count", :by => 0) { Event.count }
          should_change("Submission.count", :by => 0) { Submission.count }
        end
        context "where study is nil" do
          setup do
            Plate.create_plates_submission(@project, nil, [@rack1], @user)
          end
          should_change("Event.count", :by => 0) { Event.count }
          should_change("Submission.count", :by => 0) { Submission.count }
        end
      end

    end

    context "A Plate" do
      setup do
        @plate = Plate.create!
      end

      context "without attachments" do
        should "not report any qc_data" do
          assert @plate.qc_files.empty?
        end
      end

      context "with attached qc data" do
        setup do
          File.open("test/data/manifests/mismatched_plate.csv") do |file|
            @plate.add_qc_file file
          end
        end

        should "return any qc data" do
          assert @plate.qc_files.count ==1
          File.open("test/data/manifests/mismatched_plate.csv") do |file|
            assert_equal file.read, @plate.qc_files.first.uploaded_data.file.read
          end
        end
      end

     context "with multiple attached qc data" do
        setup do
          File.open("test/data/manifests/mismatched_plate.csv") do |file|
            @plate.add_qc_file file
            @plate.add_qc_file file
          end
        end

        should "return multiple qc data" do
          assert @plate.qc_files.count ==2
        end
      end

    end
  end


end


