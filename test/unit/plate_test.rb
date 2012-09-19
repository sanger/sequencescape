require "test_helper"

class PlateTest < ActiveSupport::TestCase

  context "" do
    context "#infinium_barcode=" do
      setup do
        @plate = Plate.new
        @plate.infinium_barcode = "AAA"
      end

      should "set the infinium barcode" do
        assert_equal "AAA", @plate.infinium_barcode
      end
    end

    context "#add_well" do
      [ [96,7,11], [384,15,23] ].each do |plate_size, row_size,col_size|
        context "for #{plate_size} plate" do
          setup do
            @well = Well.new
            @plate =Plate.new(:name => "Test Plate", :size => plate_size)
          end
          context "with valid row and col combinations" do
            (0..row_size).step(1) do |row|
              (0..col_size).step(1) do |col|
                should "not return nil: row=> #{row}, col=>#{col}" do
                  assert @plate.add_well(@well, row, col)
                end
              end
            end
          end
        end
      end
    end

    context "#sample?" do
      setup do
        @plate = Factory :plate
        @sample = Factory :sample, :name=>"abc"
        @well_asset = Well.create!.tap { |well| well.aliquots.create!(:sample => @sample) }
        @plate.add_and_save_well @well_asset
      end
      should "find the sample name if its valid" do
        assert Plate.find(@plate.id).sample?("abc")
      end
      should "not find the sample name if its invalid" do
        assert_equal false, Plate.find(@plate.id).sample?("abcdef")
      end
    end

    context "#control_well_exists?" do
      setup do
        @control_plate = Factory :control_plate, :barcode => 134443
        map = Map.find_by_description_and_asset_size("A1",96)
        @control_well_asset = Well.new(:map => map)
        @control_plate.add_and_save_well @control_well_asset
        @control_plate.reload
      end
      context "where control well is present" do
        setup do
          @plate_cw = Plate.create!
          @plate_cw.add_and_save_well Well.new
          @plate_cw.reload
          Factory :well_request, :asset => @control_well_asset, :target_asset => @plate_cw.child
        end
        should "return true" do
          assert @plate_cw.control_well_exists?
        end
      end

      context "where control well is not present" do
        setup do
          @plate_no_cw = Factory :plate
          @plate_no_cw.add_and_save_well Well.new
          @plate_no_cw.reload
        end
        should "return false" do
          assert_equal false, @plate_no_cw.control_well_exists?
        end
      end
    end
  end

  context "#plate_ids_from_requests" do
    setup do
      @well1 = Well.new
      @plate1 = Factory :plate
      @plate1.add_and_save_well(@well1)
      @request1 = Factory :well_request, :asset => @well1
    end

    context "with 1 request" do
      context "with a valid well asset" do
        should "return correct plate ids" do
          assert Plate.plate_ids_from_requests([@request1]).include?(@plate1.id)
        end
      end
    end

    context "with 2 requests on the same plate" do
      setup do
        @well2 = Well.new
        @plate1.add_and_save_well(@well2)
        @request2 = Factory :well_request, :asset => @well2
      end
      context "with a valid well assets" do
        should "return a single plate ID" do
          assert Plate.plate_ids_from_requests([@request1,@request2]).include?(@plate1.id)
          assert Plate.plate_ids_from_requests([@request2,@request1]).include?(@plate1.id)
        end
      end
    end

    context "with multiple requests on different plates" do
      setup do
        @well2 = Well.new
        @plate2 = Factory :plate
        @plate2.add_and_save_well(@well2)
        @request2 = Factory :well_request, :asset => @well2
        @well3 = Well.new
        @plate1.add_and_save_well(@well3)
        @request3 = Factory :well_request, :asset => @well3
      end
      context "with a valid well assets" do
        should "return 2 plate IDs" do
          assert Plate.plate_ids_from_requests([@request1,@request2,@request3]).include?(@plate1.id)
          assert Plate.plate_ids_from_requests([@request1,@request2,@request3]).include?(@plate2.id)
          assert Plate.plate_ids_from_requests([@request3,@request1,@request2]).include?(@plate1.id)
          assert Plate.plate_ids_from_requests([@request3,@request1,@request2]).include?(@plate2.id)
        end
      end
    end

  end

  context "Plate submission" do
    setup do
      @plate1 = Factory :plate
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

      [@plate1, @plate2,@plate3].each do |plate|
        2.times do
          plate.add_and_save_well(Well.new)
        end
      end
    end
    context "#generate_plate_submission(project, study, user, current_time)" do
      context "with valid inputs" do
        setup do
          @plate1.generate_plate_submission(@project, @study, @user, @current_time)
        end
        should_change("Event.count", :by => 1) { Event.count }
        should_change("Submission.count", :by => 1) { Submission.count }
        should_change("Request.count", :by => 0) { Request.count }
        should "not set study.errors" do
          assert_equal 0, @study.errors.count
        end
      end
      context "where project quotas are enforced" do
        context "and there is no quota available" do
          setup do
            @project.enforce_quotas = true
            @project.quotas.create(:request_type => @request_type_1, :limit => 0)
            @project.quotas.create(:request_type => @request_type_2, :limit => 0)
            @project.save
          end
          should "raise quota exception" do
            assert_raise Quota::Error do
              @plate1.generate_plate_submission(@project, @study, @user, @current_time)
            end
          end
        end
      end
    end

    context "#create_plates_submission(project, study, plates, user)" do
      context "with valid inputs" do
        context "and 1 plate" do
          setup do
            Plate.create_plates_submission(@project, @study, [@plate1], @user)
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
            Plate.create_plates_submission(@project, @study, [@plate1,@plate3,@plate2], @user)
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
            Plate.create_plates_submission(@project, @study, [@plate1], nil)
          end
          should_change("Event.count", :by => 0) { Event.count }
          should_change("Submission.count", :by => 0) { Submission.count }
        end
        context "where project is nil" do
          setup do
            Plate.create_plates_submission(nil, @study, [@plate1], @user)
          end
          should_change("Event.count", :by => 0) { Event.count }
          should_change("Submission.count", :by => 0) { Submission.count }
        end
        context "where study is nil" do
          setup do
            Plate.create_plates_submission(@project, nil, [@plate1], @user)
          end
          should_change("Event.count", :by => 0) { Event.count }
          should_change("Submission.count", :by => 0) { Submission.count }
        end
      end

    end
  end


end


