require "test_helper"

class WorkflowsController
  attr_writer :batch
end

class CherrypickTaskTest < ActiveSupport::TestCase
  context CherrypickTask do
    setup do
      pipeline = Pipeline.find_by_name('Cherrypick') or raise StandardError, "Cannot find cherrypick pipeline"
      @task = CherrypickTask.new(:workflow => pipeline.workflow)
    end 

    context "#map_empty_wells with 1 empty_well" do
      setup do
        @template = Factory :plate_template
        @template.add_and_save_well Well.new(:map=>Map.find_by_description_and_asset_size("A1",96))
      end
      should "return a hash with the empty wells" do
        empty_wells = @task.send(:map_empty_wells, @template,nil)
        assert_equal 1,empty_wells.size
        assert empty_wells.is_a?(Hash)
        assert_equal "A1", empty_wells[1]
      end
    end

    context "#map_empty_wells with 3 empty_wells" do
      setup do
        @template = Factory :plate_template
        @template.add_and_save_well Well.new(:map=>Map.find_by_description_and_asset_size("A1",96))
        @template.add_and_save_well Well.new(:map=>Map.find_by_description_and_asset_size("B1",96))
        @template.add_and_save_well Well.new(:map=>Map.find_by_description_and_asset_size("C1",96))
      end
      should "return a hash with the empty wells" do
        empty_wells = @task.send(:map_empty_wells, @template,nil)
        assert_equal 3,empty_wells.size
        assert empty_wells.is_a?(Hash)
        assert_equal "A1", empty_wells[1]
        assert_equal "B1", empty_wells[13]
        assert_equal "C1", empty_wells[25]
      end

      context "a plate with 1 filled well at E12" do
        setup do
          @plate = Factory :plate
          @plate.add_and_save_well Well.new(:map => Map.find_by_description("D2"))
        end
        should "return a hash with the empty wells" do
          empty_wells = @task.send(:map_empty_wells, @template,@plate)
          assert_equal 4,empty_wells.size
          assert empty_wells.is_a?(Hash)
          assert_equal "D2", empty_wells[38]
          assert_equal "A1", empty_wells[1]
        end
      end

      context "#map_empty_wells with 3 empty_wells and a plate with 2 filled wells where E12 should be max" do
        setup do
          @plate = Factory :plate
          @plate.add_and_save_well Well.new(:map => Map.find_by_description("D1"))
          @plate.add_and_save_well Well.new(:map => Map.find_by_description("D2"))
        end
        should "return a hash with the empty wells" do
          empty_wells = @task.send(:map_empty_wells, @template,@plate)
          assert_equal 5,empty_wells.size
          assert empty_wells.is_a?(Hash)
          assert_equal "D2", empty_wells[38]
          assert_equal "D1", empty_wells[37]
          assert_equal "A1", empty_wells[1]
        end
      end
    end

    context "a cherrypick task" do
      setup do
        pipeline = Factory :pipeline, :name => 'Starting pipeline'
        @batch   = Factory :batch, :pipeline => pipeline
        @parentasset  = Factory :well
        @parentasset2 = Factory :well
        @parentasset3 = Factory :well
        @request  =  Factory :request, :asset => @parentasset
        @request2 =  Factory :request, :asset => @parentasset2
        @request3 =  Factory :request, :asset => @parentasset3
        @plate = Factory :plate
        @plate.add_and_save_well @parentasset
        @plate.add_and_save_well @parentasset2
        @plate.add_and_save_well @parentasset3
      end

      context '#map_wells_to_plates with invalid robot' do
        should 'raise an exception when the robot has no beds' do
          assert_raise(StandardError) do
            @task.map_wells_to_plates([], nil, Factory(:robot), @batch, nil)
          end
        end
      end

      context "#map_wells_to_plates with 2 requests" do
        setup do
          @map  = Map.find_by_description_and_asset_size("A1",96)
          @map2 = Map.find_by_description_and_asset_size("B2",96)
          @request.asset.map_id  = @map.id
          @request2.asset.map_id = @map2.id
          @requests = [@request,@request2]
          @template = Factory :plate_template
          @template.add_and_save_well Well.new(:map=>Map.find_by_description_and_asset_size("A1",96))
          @template.add_and_save_well Well.new(:map=>Map.find_by_description_and_asset_size("B2",96))
          @template.add_and_save_well Well.new(:map=>Map.find_by_description_and_asset_size("H12",96))

          @robot  = Factory :robot
          @robot.robot_properties.create(:key=> 'max_plates', :value => 15)
          @robot.save
        end
        should "produce initial layout for cherrypicking" do
          cplayout = @task.map_wells_to_plates(@requests,@template,@robot,@batch,nil)
          assert_equal [@request.id,  @request.asset.parent.barcode,  @map.description],  cplayout[0][0][1]
          assert_equal [@request2.id, @request2.asset.parent.barcode, @map2.description], cplayout[0][0][2]
          assert_equal [0, "---", ""], cplayout[0][0][0]
        end
      end

      context "#map_wells_to_plates with 2 requests and a partial plate inputted and no control well" do
        setup do
          @template = Factory :plate_template
          @map  = Map.find_by_description_and_asset_size("A1",96)
          @map2 = Map.find_by_description_and_asset_size("B1",96)
          @map3 = Map.find_by_description_and_asset_size("E1",96)
          @request.asset.map_id  = @map.id
          @request2.asset.map_id = @map2.id
          @request3.asset.map_id = @map3.id
          @plate = Factory :plate
          @plate.add_and_save_well @request.asset
          @plate.add_and_save_well @request2.asset

          @robot  = Factory :robot
          @robot.robot_properties.create(:key=> 'max_plates', :value => 15)
          @robot.save

          @requests = [@request3]
        end
        should "produce initial layout for cherrypicking" do
          cplayout = @task.map_wells_to_plates(@requests,@template,@robot,@batch,@plate)
          assert_equal [0, "---", ""], cplayout[0][0][0]
          assert_equal [0, "---", ""], cplayout[0][0][1]
          assert_equal [@request3.id, @request3.asset.parent.barcode, "E1"], cplayout[0][0][2]
          assert_equal [0, "Empty", ""], cplayout[0][0][3]
        end
      end

      context "#map_wells_to_plates with 2 requests and a partial plate inputted and a control well" do
        setup do
          @template = Factory :plate_template
          @template.set_control_well(1)
          @map  = Map.find_by_description_and_asset_size("A1",96)
          @map2 = Map.find_by_description_and_asset_size("B1",96)
          @map3 = Map.find_by_description_and_asset_size("C1",96)
          @request.asset.map_id  = @map.id
          @request2.asset.map_id = @map2.id
          @request3.asset.map_id = @map3.id
          @plate = Factory :plate
          @plate.add_and_save_well @request.asset
          @plate.add_and_save_well @request2.asset

          @control_plate = Factory :control_plate, :barcode => 134443
          [["A1","Sample_111"],["C1","Sample_222"],["E1","Sample_333"],["H1","Affy1"],["G1","Affy2"]].each do |description,value|
            map = Map.find_by_description_and_asset_size(description,96)
            sample = Factory :sample, :name=> value
            well = Well.create!(:map => map, :value => value).tap { |well| well.aliquots.create!(:sample => sample) }
            @control_plate.add_and_save_well well
          end

          @control_request = @task.create_control_request(@batch,@plate,@template)
          @parentasset4 = Factory :asset
          @assetlink4  = Factory :asset_link, :ancestor_id => @parentasset4.id,  :descendant_id => @control_request.asset.id
          @map4 = Map.find_by_description_and_asset_size("C1",96)
          @control_request.asset.map_id  = @map4.id
          @plate.add_and_save_well @control_request.asset
          @robot  = Factory :robot
          @robot.robot_properties.create(:key=> 'max_plates', :value => 15)
          @robot.save

          @requests = [@request3]
          @plate.reload
        end
        should "produce initial layout for cherrypicking" do
          assert_not_nil @control_request
          cplayout = @task.map_wells_to_plates(@requests,@template,@robot,@batch,@plate)
          assert_equal [0, "---", ""], cplayout[0][0][0]
          assert_equal [0, "---", ""], cplayout[0][0][1]
          assert_equal [0, "---", ""], cplayout[0][0][2]
          assert_equal [@request3.id, @request3.asset.parent.barcode, "C1"], cplayout[0][0][3]
          assert_equal @control_request.asset.parent.barcode,cplayout[0][0][4][1]
          assert_equal [0, "Empty", ""], cplayout[0][0][5]
        end
      end

      context "#map_wells_to_plates with 2 requests with a control well on the template" do
        setup do
          @map  = Map.find_by_description_and_asset_size("A1",96)
          @map2 = Map.find_by_description_and_asset_size("B1",96)
          @request.asset.map_id  = @map.id
          @request2.asset.map_id = @map2.id
          @requests = [@request,@request2]
          @template = Factory :plate_template
          @template.add_and_save_well Well.new(:map=>Map.find_by_description_and_asset_size("A1",96))
          @template.add_and_save_well Well.new(:map=>Map.find_by_description_and_asset_size("B2",96))
          @template.add_and_save_well Well.new(:map=>Map.find_by_description_and_asset_size("H12",96))
          @template.set_control_well(1)
          @robot  = Factory :robot
          @robot.robot_properties.create(:key=> 'max_plates', :value => 15)
          @robot.save
          @plate = Factory :control_plate, :barcode => 134443
          [["A1","Sample_111"],["C1","Sample_222"],["E1","Sample_333"]].each do |description,value|
            map = Map.find_by_description_and_asset_size(description,96)
            sample = Factory :sample, :name=> value
            well = Well.create!(:map => map, :value => value).tap { |well| well.aliquots.create!(:sample => sample) }
            @plate.add_and_save_well well
          end
          @plate.reload

        end
        should "produce initial layout for cherrypicking" do
          cplayout = @task.map_wells_to_plates(@requests,@template,@robot,@batch,nil)
          assert_equal [@request.id,  @request.asset.parent.barcode,  @map.description],  cplayout[0][0][1]
          assert_equal [@request2.id, @request2.asset.parent.barcode, @map2.description], cplayout[0][0][2]
          assert_equal ControlPlate.find(@plate).barcode, cplayout[0][0][3][1]
          assert_equal [0, "---", ""], cplayout[0][0][0]
        end
      end

      context "#create_control_request" do
        setup do
          @plate = Factory :control_plate, :barcode => 134443
          [["A1","Sample_111"],["C1","Sample_222"],["E1","Sample_333"],["H1","Affy1"],["G1","Affy2"]].each do |description,value|
            map = Map.find_by_description_and_asset_size(description,96)
            sample = Factory :sample, :name=> value
            well = Well.create!(:map => map, :value => value).tap { |well| well.aliquots.create!(:sample => sample) }
            @plate.add_and_save_well well
          end
          @template = Factory :plate_template
          @template.add_and_save_well Well.new(:map=>Map.find_by_description_and_asset_size("A1",96))
          @template.set_control_well(1)
          @plate.reload
        end
        should "randomly return a request and correct asset" do
          request = @task.create_control_request(@batch,nil,@template)
          assert request.is_a?(Request)
          assert_equal false, request.asset.nil?
          assert_equal false, request.target_asset.nil?
          assert_equal false, ["A1","C1","E1"].index(request.asset.map.description).nil?
        end
      end
    end

    context "#parse_spreadsheet_row" do
      [96,384].each do |plate_size|
        context "on a plate size of #{plate_size}" do
          context "with valid data" do
            [ ["1234","an Asset Name","a plate key", "A1"],
              ["986","","a plate key", "A5"],
              ["1234","an Asset Name","567", "B1"],
              ["1234","an Asset Name","", "C1"],
              ["1234","","", "F5"],
              ["1234","xx","xx", "H12"],
              ["1234","xx","xx", "H12","A4","A5","A6"],
              ["1234","xx","xx", "E7"]
            ].each do |input_row|
              should "return array of valid formatted data for #{input_row.join(',')}" do
                @well_layout = CherrypickTask.parse_spreadsheet_row(input_row,plate_size)
                assert @well_layout.is_a?(Array)
                assert @well_layout[0].is_a?(String)
                assert @well_layout[1].is_a?(Integer)
                assert @well_layout[2].is_a?(Integer)
                assert_equal Map.description_to_vertical_plate_position(input_row[3],plate_size), @well_layout[2]
              end
            end
          end

          context "with invalid data" do
            [ ["11","an Asset Name","a plate key", "xxx"],
              ["11","an Asset Name","a plate key", "1"],
              ["11","an Asset Name","a plate key", 1],
              ["","","", ""],
              [nil,nil,nil,nil],
              ["","an Asset Name","a plate key", "A1"],
              ["11","an Asset Name","a plate key", ""],
              ["11"],
              ["11","an Asset Name"],
              ["11","an Asset Name","a plate key"],
              [],
            ].each_with_index do |input_row,index|
              should "return nil for test #{index}" do
                @well_layout = CherrypickTask.parse_spreadsheet_row(input_row,plate_size)
                assert_equal nil, @well_layout
              end
            end
          end

        end
      end
    end

    context "Creating a control request" do
      setup do
        @workflow  = WorkflowsController.new
        @br        = Factory :batch_request
        @workflow.batch = @br.batch
        #@task = Factory :cherrypick_task
        @sample = Factory :sample
        @well = Factory(:well).tap { |well| well.aliquots.create!(:sample => @sample) }
      end
      context "#create_control_request_and_add_to_batch(task,control_param)" do
        context "with valid inputs" do
          setup do
            @request_id = @workflow.create_control_request_and_add_to_batch(@task,"control[#{@well.id}]")
          end
          should_change("Request.count", :by => 1) { Request.count }
          should_change("Well.count", :by => 1) { Well.count }
        end
      end

      context "#create_control_request_from_well(control_param)" do
        context "with valid inputs" do
          setup do
            @request = @task.create_control_request_from_well("control[#{@well.id}]")
          end
          should "return a request" do
            assert @request.is_a?(Request)
            assert_not_nil @request
          end
          should_change("Request.count", :by => 1) { Request.count }
          should_change("Well.count", :by => 1) { Well.count }
        end
        context "with invalid input" do
          setup do
            @request = @task.create_control_request_from_well("#{@well.id}")
          end
          should "return nil" do
            assert @request.nil?
          end
          should_change("Request.count", :by => 0) { Request.count }
          should_change("Well.count", :by => 0) { Well.count }
        end
        context "with invalid well" do
          setup do
            @request = @task.create_control_request_from_well("control[99999]")
          end
          should "return nil" do
            assert @request.nil?
          end
          should_change("Request.count", :by => 0) { Request.count }
          should_change("Well.count", :by => 0) { Well.count }
        end

      end
    end

  end
end
