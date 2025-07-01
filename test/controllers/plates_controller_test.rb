# frozen_string_literal: true

require 'test_helper'

class PlatesControllerTest < ActionController::TestCase
  context 'Plate' do
    setup do
      @controller = PlatesController.new
      @request = ActionController::TestRequest.create(@controller)

      @pico_purposes = create_list(:pico_assay_purpose, 2)
      @working_dilution = create_list(:working_dilution_plate_purpose, 1)

      @pico_assay_plate_creator = FactoryBot.create(:plate_creator, plate_purposes: @pico_purposes)
      @dilution_plates_creator = FactoryBot.create(:plate_creator, plate_purposes: @working_dilution)

      @barcode_printer = create(:barcode_printer)

      PlateBarcode.stubs(:create_barcode).returns(
        build(:plate_barcode, barcode: 'SQPD-1234567'),
        build(:plate_barcode, barcode: 'SQPD-1234568'),
        build(:plate_barcode, barcode: 'SQPD-1234569'),
        build(:plate_barcode, barcode: 'SQPD-1234570'),
        build(:plate_barcode, barcode: 'SQPD-1234571'),
        build(:plate_barcode, barcode: 'SQPD-1234572')
      )
      PlateBarcode.stubs(:create_child_barcodes).returns([build(:child_plate_barcode)])
      LabelPrinter::PmbClient.stubs(:get_label_template_by_name).returns('data' => [{ 'id' => 15 }])
      LabelPrinter::PmbClient.stubs(:print).returns(200)
    end

    context 'with a logged in user' do
      setup do
        @user = FactoryBot.create(:user, barcode: 'ID100I', swipecard_code: '1234567')
        @user.grant_administrator
        session[:user] = @user.id

        @parent_plate = FactoryBot.create(:plate)
        @parent_plate.wells << [create(:untagged_well)]

        @parent_plate2 = FactoryBot.create(:plate)
        @parent_plate2.wells << [create(:untagged_well)]

        @parent_plate3 = FactoryBot.create(:plate)
        @parent_plate3.wells << [create(:untagged_well)]
      end

      context '#new' do
        setup { get :new }
        should respond_with :success
        should_not set_flash
      end

      context '#create' do
        context 'with no source plates' do
          setup do
            @plate_count = Plate.count
            post :create,
                 params: {
                   plates: {
                     creator_id: @dilution_plates_creator.id,
                     barcode_printer: @barcode_printer.id,
                     user_barcode: '1234567'
                   }
                 }
          end

          should 'change Plate.count by 1' do
            assert_equal 1, Plate.count - @plate_count, 'Expected Plate.count to change by 1'
          end
          should respond_with :ok
          should set_flash.to(/Created/)
        end

        context 'Create a Plate' do
          context 'from a group of plates' do
            setup do
              @purpose = create(:plate_purpose, name: 'A purpose', size: 96)

              @asset_group_count = AssetGroup.count
              @num_create = 2
              @plates = Array.new(@num_create) { @purpose.create! }
              @plates.each { |plate| plate.wells << [create(:untagged_well)] }
              @plate_barcodes = @plates.map(&:barcodes).flatten.map(&:barcode)
              @create_params = {
                plates: {
                  creator_id: @dilution_plates_creator.id,
                  source_plates: @plate_barcodes.join(','),
                  barcode_printer: @barcode_printer.id,
                  user_barcode: '1234567',
                  create_asset_group: 'Yes'
                }
              }
              @plate_count = Plate.count
              post :create, params: @create_params
            end

            should 'create the plates' do
              assert_equal @plate_count + @num_create, Plate.count
            end

            should_not set_flash[:error].to(/Could not find plate/)

            should 'display created barcodes' do
              assert_equal(true, response.body.include?('Created labware'))
            end

            context 'when one of the scanned source plates do not exist' do
              setup do
                @missing_barcode_create_params = {
                  plates: {
                    creator_id: @dilution_plates_creator.id,
                    source_plates: @plate_barcodes.push('missing').join(','),
                    barcode_printer: @barcode_printer.id,
                    user_barcode: '1234567',
                    create_asset_group: 'Yes'
                  }
                }
                @plates_already = Plate.count
                post :create, params: @missing_barcode_create_params
              end

              should 'rollback all group created' do
                assert_equal @plates_already, Plate.count, 'Expected Plate.count not to change'
              end

              should set_flash[:error].to(/Could not find plate/)

              should 'not display created barcodes' do
                assert_equal(false, response.body.include?('Created labware'))
              end
            end
          end
          context 'from a Heron TubeRack' do
            setup do
              tube_rack_purpose = create(:tube_rack_purpose, target_type: 'TubeRack', size: 96)
              study = create(:study)

              params = {
                purpose_uuid: tube_rack_purpose.uuid,
                study_uuid: study.uuid,
                barcode: '0000000001',
                size: 96,
                tubes: {
                  'A1' => {
                    barcode: 'FD00000001',
                    content: {
                      supplier_name: 'PHEC-nnnnnnn1'
                    }
                  },
                  'A2' => {
                    barcode: 'FD00000002',
                    content: {
                      supplier_name: 'PHEC-nnnnnnn2'
                    }
                  }
                }
              }
              tube_rack_factory = ::Heron::Factories::TubeRack.new(params)
              tube_rack_factory.save
              @tube_rack = tube_rack_factory.tube_rack
              @plate_count = Plate.count
              @asset_group_count = AssetGroup.count
              @create_params = {
                plates: {
                  creator_id: @dilution_plates_creator.id,
                  source_plates: @tube_rack.barcodes.first.barcode,
                  barcode_printer: @barcode_printer.id,
                  user_barcode: '1234567',
                  create_asset_group: 'Yes'
                }
              }
            end

            context 'when printing and asset group creation are successful' do
              setup { post :create, params: @create_params }

              should 'change Plate.count by 1' do
                assert_equal 1, Plate.count - @plate_count, 'Expected Plate.count to change by 1'
              end
              should respond_with :ok
              should set_flash[:notice].to(/Created/)
              should_not set_flash[:warning]

              should 'display the created barcode' do
                assert_equal(true, response.body.include?(@tube_rack.children.first.barcodes.first.barcode))
              end

              should 'have created an asset group' do
                assert_equal 1, AssetGroup.count - @asset_group_count, 'Expected an Asset Group to be created'
              end
            end

            context 'when one of the scanned source plates do not exist' do
              setup do
                @missing_barcode_create_params = {
                  plates: {
                    creator_id: @dilution_plates_creator.id,
                    source_plates: "#{@tube_rack.barcodes.first.barcode},missing",
                    barcode_printer: @barcode_printer.id,
                    user_barcode: '1234567',
                    create_asset_group: 'Yes'
                  }
                }
                @plates_already = Plate.count
                post :create, params: @missing_barcode_create_params
              end

              should 'rollback all group created' do
                assert_equal @plates_already, Plate.count, 'Expected Plate.count not to change'
              end

              should set_flash[:error].to(/Could not find plate/)

              should 'not display created barcodes' do
                assert_equal(false, response.body.include?('Created labware'))
              end
            end

            context 'when the printer fails to print' do
              setup do
                LabelPrinter::PrintJob.any_instance.stubs(:execute).returns(false)
                post :create, params: @create_params
              end

              should 'still display the created barcode' do
                assert_equal(true, response.body.include?(@tube_rack.children.first.barcodes.first.barcode))
              end

              should 'keep the created labware persisted' do
                barcode = @tube_rack.children.first.barcodes.first.barcode
                assert_equal(1, Plate.joins(:barcodes).where(barcodes: { barcode: }).count)
              end

              should set_flash[:warning].to(/Barcode labels failed to print/)

              should 'still have created an asset group' do
                assert_equal 1, AssetGroup.count - @asset_group_count, 'Expected an Asset Group to be created'
              end
            end

            context 'when asset group creation fails' do
              setup do
                Plate::Creator.any_instance.stubs(:find_relevant_study).returns(nil)
                post :create, params: @create_params
              end

              should set_flash[:warning].to(/Failed to create Asset Group/)
              should_not set_flash[:warning].to(/Barcode labels failed to print/)
            end
          end

          context 'with one source plate' do
            setup do
              @well = create(:well)
              @parent_plate.wells << [@well]
              @parent_raw_barcode = @parent_plate.machine_barcode
            end

            context "and we don't select any dilution factor" do
              context "when we don't have a parent" do
                setup do
                  @plate_count = Plate.count
                  post :create,
                       params: {
                         plates: {
                           creator_id: @dilution_plates_creator.id,
                           barcode_printer: @barcode_printer.id,
                           source_plates: '',
                           user_barcode: '2470000100730'
                         }
                       }
                end

                should 'change Plate.count by 1' do
                  assert_equal 1, Plate.count - @plate_count, 'Expected Plate.count to change by 1'
                end

                should 'set the dilution factor to default (1.0)' do
                  assert_equal 1.0, Plate.last.dilution_factor
                end
              end

              context "when the parent doesn't have a dilution factor" do
                setup do
                  @plate_count = Plate.count
                  post :create,
                       params: {
                         plates: {
                           creator_id: @dilution_plates_creator.id,
                           barcode_printer: @barcode_printer.id,
                           source_plates: @parent_raw_barcode.to_s,
                           user_barcode: '2470000100730'
                         }
                       }
                end

                should 'change Plate.count by 1' do
                  assert_equal 1, Plate.count - @plate_count, 'Expected Plate.count to change by 1'
                end

                should 'set the dilution factor to default (1.0)' do
                  assert_equal 1.0, @parent_plate.children.first.dilution_factor
                end
              end

              context 'when the parent plate has a dilution factor of 3.53' do
                setup do
                  @parent_plate.dilution_factor = 3.53
                  @parent_plate.save!
                  @plate_count = Plate.count
                  post :create,
                       params: {
                         plates: {
                           creator_id: @dilution_plates_creator.id,
                           barcode_printer: @barcode_printer.id,
                           source_plates: @parent_raw_barcode.to_s,
                           user_barcode: '2470000100730'
                         }
                       }
                end

                should 'change Plate.count by 1' do
                  assert_equal 1, Plate.count - @plate_count, 'Expected Plate.count to change by 1'
                end

                should 'set the dilution factor to 3.53' do
                  assert_equal 3.53, @parent_plate.children.first.dilution_factor
                end
              end

              context 'when we have 2 parents' do
                setup do
                  @well2 = create(:well)
                  @parent_plate2.wells << [@well2]
                  @parent2_raw_barcode = @parent_plate2.machine_barcode
                end

                context 'and first parent has a dilution factor of 3.53, and second parent with 4.56' do
                  setup do
                    @parent_plate.dilution_factor = 3.53
                    @parent_plate.save!

                    @parent_plate2.dilution_factor = 4.56
                    @parent_plate2.save!
                  end

                  context "and I don't select any dilution factor" do
                    setup do
                      @plate_count = Plate.count
                      post :create,
                           params: {
                             plates: {
                               creator_id: @dilution_plates_creator.id,
                               barcode_printer: @barcode_printer.id,
                               source_plates: "#{@parent_raw_barcode},#{@parent2_raw_barcode}",
                               user_barcode: '2470000100730'
                             }
                           }
                    end

                    should 'change Plate.count by 2' do
                      assert_equal 2, Plate.count - @plate_count, 'Expected Plate.count to change by 2'
                    end

                    should 'set the dilution factor of each children to 3.53 and 4.56' do
                      assert_equal 3.53, @parent_plate.children.first.dilution_factor
                      assert_equal 4.56, @parent_plate2.children.first.dilution_factor
                    end
                  end

                  context 'and I select a dilution factor of 2.0' do
                    setup do
                      @plate_count = Plate.count
                      post :create,
                           params: {
                             plates: {
                               creator_id: @dilution_plates_creator.id,
                               barcode_printer: @barcode_printer.id,
                               source_plates: "#{@parent_raw_barcode},#{@parent2_raw_barcode}",
                               user_barcode: '2470000100730',
                               dilution_factor: 2.0
                             }
                           }
                    end

                    should 'change Plate.count by 2' do
                      assert_equal 2, Plate.count - @plate_count, 'Expected Plate.count to change by 2'
                    end

                    should 'set the dilution factor of each children to 7.06 and 9.12' do
                      # This test showed different behaviour between MRI and jruby
                      # In particular, the dilution factors are represented as BigDecimals
                      # and while MRI reports inequality with the float, Jruby declares them equal.
                      # This isn't actually true for ALL floats and their big decimal 'equivalent'
                      # so presumably its due to the accuracy of the float.
                      assert_equal 7.06, @parent_plate.children.first.dilution_factor.to_f
                      assert_equal 9.12, @parent_plate2.children.first.dilution_factor.to_f
                    end
                  end
                end
              end
            end

            context 'and we select a dilution factor of 12.0' do
              context "when we don't have a parent" do
                setup do
                  @plate_count = Plate.count
                  post :create,
                       params: {
                         plates: {
                           creator_id: @dilution_plates_creator.id,
                           barcode_printer: @barcode_printer.id,
                           source_plates: '',
                           user_barcode: '2470000100730',
                           dilution_factor: 12.0
                         }
                       }
                end

                should 'change Plate.count by 1' do
                  assert_equal 1, Plate.count - @plate_count, 'Expected Plate.count to change by 1'
                end

                should 'set the dilution factor to 12.0' do
                  assert_equal 12.0, Plate.last.dilution_factor
                end
              end
              context "when the parent doesn't have a dilution factor" do
                setup do
                  @plate_count = Plate.count
                  post :create,
                       params: {
                         plates: {
                           creator_id: @dilution_plates_creator.id,
                           barcode_printer: @barcode_printer.id,
                           source_plates: @parent_raw_barcode.to_s,
                           user_barcode: '2470000100730',
                           dilution_factor: 12.0
                         }
                       }
                end

                should 'change Plate.count by 1' do
                  assert_equal 1, Plate.count - @plate_count, 'Expected Plate.count to change by 1'
                end

                should 'set the dilution factor to 12.0' do
                  assert_equal 12.0, @parent_plate.children.first.dilution_factor
                end
              end

              context 'when the parent plate has a dilution factor of 4.0' do
                setup do
                  @plate_count = Plate.count
                  @parent_plate.dilution_factor = 4
                  @parent_plate.save!
                  post :create,
                       params: {
                         plates: {
                           creator_id: @dilution_plates_creator.id,
                           barcode_printer: @barcode_printer.id,
                           source_plates: @parent_raw_barcode.to_s,
                           user_barcode: '2470000100730',
                           dilution_factor: 12.0
                         }
                       }
                end

                should 'change Plate.count by 1' do
                  assert_equal 1, Plate.count - @plate_count, 'Expected Plate.count to change by 1'
                end

                should 'sets the dilution factor to 48.0 (parent=4*child=12)' do
                  assert_equal 48.0, @parent_plate.children.first.dilution_factor
                end
              end
            end
          end
        end

        context 'Create Pico Assay Plates' do
          context 'with one source plate' do
            setup { @parent_raw_barcode = @parent_plate.machine_barcode }

            context 'without a dilution factor' do
              setup do
                @picoassayplate_count = PicoAssayPlate.count
                post :create,
                     params: {
                       plates: {
                         creator_id: @pico_assay_plate_creator.id,
                         barcode_printer: @barcode_printer.id,
                         source_plates: @parent_raw_barcode.to_s,
                         user_barcode: '2470000100730'
                       }
                     }
              end

              should 'change PicoAssayPlate.count by 2' do
                assert_equal 2,
                             PicoAssayPlate.count - @picoassayplate_count,
                             'Expected PicoAssayPlate.count to change by 2'
              end

              should 'add a child to the parent plate' do
                assert Plate.find(@parent_plate.id).children.first.is_a?(Plate)
                assert_equal @pico_purposes.first, Plate.find(@parent_plate.id).children.first.plate_purpose
              end

              should respond_with :ok

              should set_flash.to(/Created/)
            end

            context 'with a parent with dilution factor 4 and a specified dilution factor 12' do
              setup do
                @parent_plate.dilution_factor = 4
                @parent_plate.save!
                post :create,
                     params: {
                       plates: {
                         creator_id: @pico_assay_plate_creator.id,
                         barcode_printer: @barcode_printer.id,
                         source_plates: @parent_raw_barcode.to_s,
                         dilution_factor: 12.0,
                         user_barcode: '2470000100730'
                       }
                     }
              end

              should 'create all the pico assay plates with dilution factor 48' do
                childrens = Plate.find(@parent_plate.id).children
                assert_equal 48.0, childrens.first.dilution_factor
                assert_equal 1, childrens.map(&:dilution_factor).uniq.length
              end
            end
          end

          context 'with 3 source plates' do
            setup do
              @picoassayplate_count = PicoAssayPlate.count
              @parent_raw_barcode = @parent_plate.machine_barcode
              @parent_raw_barcode2 = @parent_plate2.machine_barcode
              @parent_raw_barcode3 = @parent_plate3.machine_barcode
              post :create,
                   params: {
                     plates: {
                       creator_id: @pico_assay_plate_creator.id,
                       barcode_printer: @barcode_printer.id,
                       source_plates: "#{@parent_raw_barcode}\n#{@parent_raw_barcode2}\t#{@parent_raw_barcode3}",
                       user_barcode: '2470000100730'
                     }
                   }
            end

            should 'change PicoAssayPlate.count by 6' do
              assert_equal 6,
                           PicoAssayPlate.count - @picoassayplate_count,
                           'Expected PicoAssayPlate.count to change by 6'
            end

            should 'have child plates' do
              [@parent_plate, @parent_plate2, @parent_plate3].each do |plate|
                assert Plate.find(plate.id).children.first.is_a?(Plate)
                assert_equal @pico_purposes.first, Plate.find(plate.id).children.first.plate_purpose
              end
            end
            should respond_with :ok
            should set_flash.to(/Created/)
          end
        end
      end
    end
  end
end
