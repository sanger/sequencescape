# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015,2016 Genome Research Ltd.

require 'test_helper'
require 'studies/sample_registration_controller'

class Studies::SampleRegistrationControllerTest < ActionController::TestCase
  context 'Studies::SampleRegistrationController' do
    setup do
      @controller = Studies::SampleRegistrationController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
      @study      = FactoryGirl.create :study
    end

    should_require_login

    context 'when logged in' do
      setup do
        @user = FactoryGirl.create :user
        @controller.stubs(:logged_in?).returns(@user)
        session[:user] = @user.id
      end

      context '#index' do
        setup do
          get :index, study_id: @study
        end

        should respond_with :success
        should render_template :index
      end

      context '#new' do
        setup do
          get :new, study_id: @study
        end

        should 'respond successfully and render the new template' do
          assert_response :success
          assert_template :new
        end

        context 'without attaching a file' do
          setup do
            post :new, study_id: @study
          end

          should 'respond successfully and render the new template' do
            assert_response :success
            assert_template :new
          end
        end

        context 'with attached file' do
          setup do
            session[:user] = @user.id
            post :spreadsheet, study_id: @study, file: Rack::Test::UploadedFile.new(Rails.root.to_s + '/test/data/two_plate_sample_info_valid.xls', '')
          end

          should 'respond successfully and render the new template' do
            assert_response :success
            assert_template :new
          end
        end

        context 'with invalid file' do
          setup do
            post :spreadsheet, study_id: @study, file: Rack::Test::UploadedFile.new(Rails.root.to_s + '/config/environment.rb', 'text/csv')
          end

          should set_flash.to('Problems processing your file. Only Excel spreadsheets accepted')
          should redirect_to('upload study sample registration') { upload_study_sample_registration_index_path }
        end
      end

      context '#upload' do
        setup do
          get :upload, study_id: @study
        end

        should respond_with :success
        should render_template :upload
      end

      context '#create' do
        context 'samples are blank with values given' do
          setup do
            post :create, study_id: @study, sample_registrars: {}
          end

          should set_flash.now.to('You do not appear to have specified any samples')

          should render_template :new
        end

        context 'one sample with values given' do
          setup do
            @sscount = @study.samples.count
            post :create, study_id: @study,
                          sample_registrars: {
                '1' => {
                  asset_group_name: 'asset_group_name',
                  sample_attributes: { name: 'hello' }
                }
              }
          end

          should respond_with :redirect

          should 'change @study.samples.count by 1' do
          assert_equal 1, @study.samples.count - @sscount, 'Expected @study.samples.count to change by 1'
          end
        end

        context 'two samples with values given' do
          setup do
            @sscount = @study.samples.count
            post :create, study_id: @study,
                          sample_registrars: {
                '1' => {
                  asset_group_name: 'asset_group_0',
                  sample_attributes: { name: 'Sam1' }
                },
                '2' => {
                  asset_group_name: 'asset_group_0',
                  sample_attributes: { name: 'Sam2' }
                }
              }
          end

          should respond_with :redirect

          should 'change @study.samples.count by 2' do
            assert_equal 2, @study.samples.count - @sscount, 'Expected @study.samples.count to change by 2'
          end
        end

        context 'three samples with one ignored' do
          setup do
            @sscount = @study.samples.count
            post :create, study_id: @study,
                          sample_registrars: {
                '1' => {
                  asset_group_name: 'asset_group_0',
                  sample_attributes: { name: 'Sam1' }
                },
                '2' => {
                  ignore: '1',
                  asset_group_name: 'asset_group_0',
                  sample_attributes: { name: 'Sam2' }
                },
                '3' => {
                  asset_group_name: 'asset_group_0',
                  sample_attributes: { name: 'Sam3' }
                }
              }
          end

          should respond_with :redirect

          should 'change @study.samples.count by 2' do
            assert_equal 2, @study.samples.count - @sscount, 'Expected @study.samples.count to change by 2'
          end

          should 'not have registered sample 2' do
            assert_nil(Sample.find_by(name: 'Sam2'))
          end
        end

        context 'when a 2D barcode is passed in' do
          setup do
            @sscount = @study.samples.count
            @asset_count = Asset.count
            post :create, study_id: @study,
                          sample_registrars: {
                  '1' => {
                    asset_group_name: 'asset_group_0',
                    sample_tube_attributes: { two_dimensional_barcode: 'SI0000012345' },
                    sample_attributes: { name: 'Sam1' }
                  },
                  '2' => {
                    asset_group_name: 'asset_group_0',
                    sample_tube_attributes: { two_dimensional_barcode: 'SI0000098765' },
                    sample_attributes: { name: 'Sam2' }
                  }
                }
          end

          should respond_with :redirect

          should 'change @study.samples.count by 2' do
            assert_equal 2,  @study.samples.count - @sscount, 'Expected @study.samples.count to change by 2'
          end

          should 'change Asset.count by 2' do
            assert_equal 2,  Asset.count - @asset_count, 'Expected Asset.count to change by 2'
          end

          context 'sample 1' do
            setup do
              @sample = Sample.find_by(name: 'Sam1')
            end

            should 'have the 2D barcode on the asset' do
              assert_equal 'SI0000012345', @sample.assets.first.two_dimensional_barcode
            end
          end

          context 'sample 2' do
            setup do
              @sample = Sample.find_by(name: 'Sam2')
            end

            should 'have the 2D barcode on the asset' do
              assert_equal 'SI0000098765', @sample.assets.first.two_dimensional_barcode
            end
          end
        end

        context 'when sample information is missing' do
          setup do
            post :create, study_id: @study,
                          sample_registrars: { '1' => {} }
          end
          should render_template :new
        end

        # TODO: samples with duplicate well IDs
        # Interface behaviour has changed slightly. We might want to reinstate this behaviour in future.
      end
    end
  end
end
