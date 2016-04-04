#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

require "test_helper"

class PlatesControllerTest < ActionController::TestCase
  context "Plate" do
    setup do
      @controller = PlatesController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new

      @pico_assay_plate_creator    =FactoryGirl.create :plate_creator,  {
        :plate_purpose => PlatePurpose.find_by_name!('Pico Assay Plates')
      }
      ['Pico Assay A', 'Pico Assay B'].map do |s|
        PlatePurpose.find_by_name!(s)
      end.map do |p|
       FactoryGirl.create :plate_creator_purpose, { :plate_purpose => p, :plate_creator =>  @pico_assay_plate_creator }
      end
      @dilution_plates_creator     =FactoryGirl.create :plate_creator,  :plate_purpose => PlatePurpose.find_by_name!('Working dilution')

      create :plate_creator_purpose, {
        :plate_purpose => PlatePurpose.find_by_name!('Working dilution'),
        :plate_creator =>  @dilution_plates_creator
      }

      @gel_dilution_plates_creator =FactoryGirl.create :plate_creator,  :plate_purpose => PlatePurpose.find_by_name!('Gel Dilution Plates')

      @barcode_printer = mock("printer abc")
      @barcode_printer.stubs(:id).returns(1)
      @barcode_printer.stubs(:name).returns("abc")
      @barcode_printer.stubs(:print_labels).returns(nil)
      @barcode_printer.stubs(:map).returns(["abc",1])
      @barcode_printer.stubs(:first).returns(@barcode_printer)
      BarcodePrinter.stubs(:find).returns(@barcode_printer)
      @plate_barcode = mock("plate barcode")
      @plate_barcode.stubs(:barcode).returns("1234567")
      PlateBarcode.stubs(:create).returns(@plate_barcode)
      @barcode_printer.stubs(:each).returns(@barcode_printer )
      @barcode_printer.stubs(:blank?).returns(true)
    end

    context "with a logged in user" do
      setup do
        @user =FactoryGirl.create :user, :barcode => 'ID100I'
        @user.is_administrator
        @controller.stubs(:current_user).returns(@user)

        @parent_plate  =FactoryGirl.create :plate, :barcode => "5678"
        @parent_plate2 =FactoryGirl.create :plate, :barcode => "1234"
        @parent_plate3 =FactoryGirl.create :plate, :barcode => "987"
      end

      context "#new" do
        setup do
          get :new
        end
        should respond_with :success
        should_not set_flash
      end

      context "#create" do

       context "with no source plates" do
          setup do
            @plate_count =  Plate.count
            post :create, :plates => {:creator_id => @gel_dilution_plates_creator.id, :barcode_printer => @barcode_printer.id, :user_barcode => '2470000100730'}
          end

          should "change Plate.count by 1" do
            assert_equal 1,  Plate.count  - @plate_count, "Expected Plate.count to change by 1"
          end
          should respond_with :redirect
          should set_flash.to( /Created/)
        end

        context "Create a Plate" do
          context "with one source plate" do
            setup do
              @well =  create :well
              @parent_plate.wells << [@well]
              @parent_raw_barcode = Barcode.calculate_barcode(Plate.prefix, @parent_plate.barcode.to_i)
            end

            context "and we don't select any dilution factor" do
              context "when we don't have a parent" do
                setup do
                  @plate_count =  Plate.count
                  post :create, :plates => {:creator_id =>  @dilution_plates_creator.id, :barcode_printer => @barcode_printer.id,
                    :source_plates =>"", :user_barcode => '2470000100730'}
                end

                should "change Plate.count by 1" do
                  assert_equal 1,  Plate.count  - @plate_count, "Expected Plate.count to change by 1"
                end

                should "set the dilution factor to default (1.0)" do
                  assert_equal 1.0, Plate.last.dilution_factor
                end

              end

              context "when the parent doesn't have a dilution factor" do
                setup do
                  @plate_count =  Plate.count
                  post :create, :plates => {:creator_id =>  @dilution_plates_creator.id, :barcode_printer => @barcode_printer.id,
                    :source_plates =>"#{@parent_raw_barcode}", :user_barcode => '2470000100730'}
                end

                should "change Plate.count by 1" do
                  assert_equal 1,  Plate.count  - @plate_count, "Expected Plate.count to change by 1"
                end

                should "set the dilution factor to default (1.0)" do
                  assert_equal 1.0, @parent_plate.children.first.dilution_factor
                end
              end

              context "when the parent plate has a dilution factor of 3.53" do
                setup do
                  @parent_plate.dilution_factor=3.53
                  @parent_plate.save!
                  @plate_count =  Plate.count
                  post :create, :plates => {:creator_id =>  @dilution_plates_creator.id, :barcode_printer => @barcode_printer.id,
                    :source_plates =>"#{@parent_raw_barcode}", :user_barcode => '2470000100730'}
                end

                should "change Plate.count by 1" do
                  assert_equal 1,  Plate.count  - @plate_count, "Expected Plate.count to change by 1"
                end

                should "set the dilution factor to 3.53" do
                  assert_equal 3.53, @parent_plate.children.first.dilution_factor
                end
              end

              context "when we have 2 parents" do
                setup do
                  @well2 =  create :well
                  @parent_plate2.wells << [@well2]
                  @parent2_raw_barcode = Barcode.calculate_barcode(Plate.prefix, @parent_plate2.barcode.to_i)
                end

                context "and first parent has a dilution factor of 3.53, and second parent with 4.56" do
                  setup do
                    @parent_plate.dilution_factor=3.53
                    @parent_plate.save!

                    @parent_plate2.dilution_factor=4.56
                    @parent_plate2.save!
                  end

                  context "and I don't select any dilution factor" do
                    setup do
                      @plate_count =  Plate.count
                      post :create, :plates => {:creator_id =>  @dilution_plates_creator.id, :barcode_printer => @barcode_printer.id,
                        :source_plates =>"#{@parent_raw_barcode},#{@parent2_raw_barcode}", :user_barcode => '2470000100730'}
                    end

                    should "change Plate.count by 2" do
                      assert_equal 2,  Plate.count  - @plate_count, "Expected Plate.count to change by 2"
                    end

                    should "set the dilution factor of each children to 3.53 and 4.56" do
                      assert_equal 3.53, @parent_plate.children.first.dilution_factor
                      assert_equal 4.56, @parent_plate2.children.first.dilution_factor
                    end
                  end

                  context "and I select a dilution factor of 2.0" do
                    setup do
                      @plate_count =  Plate.count
                      post :create, :plates => {:creator_id =>  @dilution_plates_creator.id, :barcode_printer => @barcode_printer.id,
                        :source_plates =>"#{@parent_raw_barcode},#{@parent2_raw_barcode}", :user_barcode => '2470000100730',
                        :dilution_factor => 2.0
                      }
                    end

                    should "change Plate.count by 2" do
                      assert_equal 2,  Plate.count  - @plate_count, "Expected Plate.count to change by 2"
                    end

                    should "set the dilution factor of each children to 7.06 and 9.12" do
                      assert_equal 7.06, @parent_plate.children.first.dilution_factor
                      assert_equal 9.12, @parent_plate2.children.first.dilution_factor
                    end
                  end
                end
              end
            end

            context "and we select a dilution factor of 12.0" do
              context "when we don't have a parent" do
                setup do
                  @plate_count =  Plate.count
                  post :create, :plates => {:creator_id =>  @dilution_plates_creator.id, :barcode_printer => @barcode_printer.id,
                    :source_plates =>"", :user_barcode => '2470000100730',
                    :dilution_factor => 12.0 }
                end

                should "change Plate.count by 1" do
                  assert_equal 1,  Plate.count  - @plate_count, "Expected Plate.count to change by 1"
                end

                should "set the dilution factor to 12.0" do
                  assert_equal 12.0, Plate.last.dilution_factor
                end
              end
              context "when the parent doesn't have a dilution factor" do
                setup do
                  @plate_count =  Plate.count
                  post :create, :plates => {:creator_id =>  @dilution_plates_creator.id, :barcode_printer => @barcode_printer.id,
                    :source_plates =>"#{@parent_raw_barcode}", :user_barcode => '2470000100730',
                    :dilution_factor => 12.0 }
                end

                should "change Plate.count by 1" do
                  assert_equal 1,  Plate.count  - @plate_count, "Expected Plate.count to change by 1"
                end

                should "set the dilution factor to 12.0" do
                  assert_equal 12.0, @parent_plate.children.first.dilution_factor
                end
              end

              context "when the parent plate has a dilution factor of 4.0" do
                setup do
                  @plate_count =  Plate.count
                  @parent_plate.dilution_factor=4
                  @parent_plate.save!
                  post :create, :plates => {:creator_id =>  @dilution_plates_creator.id, :barcode_printer => @barcode_printer.id,
                    :source_plates =>"#{@parent_raw_barcode}", :user_barcode => '2470000100730',
                    :dilution_factor => 12.0 }
                end

                should "change Plate.count by 1" do
                  assert_equal 1,  Plate.count  - @plate_count, "Expected Plate.count to change by 1"
                end

                should "sets the dilution factor to 48.0 (parent=4*child=12)" do
                  assert_equal 48.0, @parent_plate.children.first.dilution_factor
                end
              end
            end
          end
        end

        context "Create Pico Assay Plates" do
          context "with one source plate" do
            setup do
              @parent_raw_barcode = Barcode.calculate_barcode(Plate.prefix, @parent_plate.barcode.to_i)
            end

            context "without a dilution factor" do
              setup do
                @picoassayplate_count =  PicoAssayPlate.count
                post :create, :plates => {:creator_id => @pico_assay_plate_creator.id, :barcode_printer => @barcode_printer.id,
                  :source_plates =>"#{@parent_raw_barcode}", :user_barcode => '2470000100730' }
              end

              should "change PicoAssayPlate.count by 2" do
                assert_equal 2,  PicoAssayPlate.count - @picoassayplate_count, "Expected PicoAssayPlate.count to change by 2"
              end

              should "add a child to the parent plate" do
                assert Plate.find(@parent_plate.id).children.first.is_a?(Plate)
                assert_equal PicoAssayPlatePurpose.find_by_name("Pico Assay A"), Plate.find(@parent_plate.id).children.first.plate_purpose
              end

              should respond_with :redirect

              should set_flash.to(/Created/)
            end

            context "with a parent with dilution factor 4 and a specified dilution factor 12" do
              setup do
                @parent_plate.dilution_factor = 4
                @parent_plate.save!
                post :create, :plates => {:creator_id => @pico_assay_plate_creator.id,
                  :barcode_printer => @barcode_printer.id, :source_plates =>"#{@parent_raw_barcode}",
                  :dilution_factor => 12.0,
                  :user_barcode => '2470000100730' }
              end

              should "create all the pico assay plates with dilution factor 48" do
                childrens = Plate.find(@parent_plate.id).children
                assert_equal 48.0, childrens.first.dilution_factor
                assert_equal 1, childrens.map(&:dilution_factor).uniq.length
              end
            end
          end

          context "with 3 source plates" do
            setup do
              @picoassayplate_count =  PicoAssayPlate.count
              @parent_raw_barcode  = Barcode.calculate_barcode(Plate.prefix, @parent_plate.barcode.to_i)
              @parent_raw_barcode2 = Barcode.calculate_barcode(Plate.prefix, @parent_plate2.barcode.to_i)
              @parent_raw_barcode3 = Barcode.calculate_barcode(Plate.prefix, @parent_plate3.barcode.to_i)
              post :create, :plates => {:creator_id => @pico_assay_plate_creator.id, :barcode_printer => @barcode_printer.id, :source_plates =>"#{@parent_raw_barcode}\n#{@parent_raw_barcode2}\t#{@parent_raw_barcode3}", :user_barcode => '2470000100730'}
            end

            should "change PicoAssayPlate.count by 6" do
              assert_equal 6,  PicoAssayPlate.count  - @picoassayplate_count, "Expected PicoAssayPlate.count to change by 6"
            end

            should "have child plates" do
              [@parent_plate, @parent_plate2, @parent_plate3].each do  |plate|
                assert Plate.find(plate.id).children.first.is_a?(Plate)
                assert_equal PicoAssayPlatePurpose.find_by_name("Pico Assay A"), Plate.find(plate.id).children.first.plate_purpose
              end
            end
            should respond_with :redirect
            should set_flash.to( /Created/)
          end
        end

      end
    end
  end
end
