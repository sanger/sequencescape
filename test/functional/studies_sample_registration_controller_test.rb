require "test_helper"
require 'studies/sample_registration_controller'

class Studies::SampleRegistrationControllerTest < ActionController::TestCase
  context "Studies::SampleRegistrationController" do
    setup do
      @controller = Studies::SampleRegistrationController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
      @study    = Factory :study
    end

    should_require_login

    context "when logged in" do
      setup do
        @user = Factory :user
        @controller.stubs(:logged_in?).returns(@user)
        @controller.stubs(:current_user).returns(@user)
      end

      context "#index" do
        setup do
          get :index, :study_id => @study
        end

        should_respond_with :success
        should_render_template :index
      end

      context "#new" do
        setup do
          get :new, :study_id => @study
        end

        should "respond successfully and render the new template" do
          assert_response :success
          assert_template :new
        end

        context "without attaching a file" do
          setup do
            post :new, :study_id => @study
          end

          should "respond successfully and render the new template" do
            assert_response :success
            assert_template :new
          end
        end

        context "with attached file" do
          setup do
            @controller.stubs(:current_user).returns(@user)
            post :new, :study_id => @study, :file => File.open(RAILS_ROOT + '/test/data/two_plate_sample_info_valid.xls')
          end

          should "respond successfully and render the new template" do
            assert_response :success
            assert_template :new
          end
        end

        context "with invalid file" do
          setup do
            post :new, :study_id => @study, :file => File.open(RAILS_ROOT + '/config/environment.rb')
          end

          should_set_the_flash_to "Problems processing your file. Only Excel spreadsheets accepted"
          should_redirect_to("upload study sample registration") { upload_study_sample_registration_path }
        end
      end

      context "#upload" do
        setup do
          get :upload, :study_id => @study
        end

        should_respond_with :success
        should_render_template :upload
      end

      context "#create" do
        context "samples are blank with values given" do
          setup do
            post :create, :study_id => @study, :sample_registrars => {}
          end

          should_set_the_flash_to 'You do not appear to have specified any samples'
          should_render_template :new
        end

        context "one sample with values given" do
          setup do
            post :create, :study_id => @study,
              :sample_registrars => {
                '1' => {
                  :asset_group_name => 'asset_group_name',
                  :sample_attributes => { :name => 'hello' }
                }
              }
          end

          should_respond_with :redirect
          should_change('@study.samples.count', :by => 1) { @study.samples.count }
        end

        context "two samples with values given" do
          setup do
            post :create, :study_id => @study,
              :sample_registrars => {
                '1' => {
                  :asset_group_name  => 'asset_group_0',
                  :sample_attributes => { :name => 'Sam1' }
                },
                '2' => {
                  :asset_group_name  => 'asset_group_0',
                  :sample_attributes => { :name => 'Sam2' }
                }
              }
          end

          should_respond_with :redirect
          should_change('@study.samples.count', :by => 2) { @study.samples.count }
        end

        context 'three samples with one ignored' do
          setup do
            post :create, :study_id => @study,
              :sample_registrars => {
                '1' => {
                  :asset_group_name  => 'asset_group_0',
                  :sample_attributes => { :name => 'Sam1' }
                },
                '2' => {
                  :ignore            => '1',
                  :asset_group_name  => 'asset_group_0',
                  :sample_attributes => { :name => 'Sam2' }
                },
                '3' => {
                  :asset_group_name  => 'asset_group_0',
                  :sample_attributes => { :name => 'Sam3' }
                }
              }
          end

          should_respond_with :redirect
          should_change('@study.samples.count', :by => 2) { @study.samples.count }

          should 'not have registered sample 2' do
            assert_nil(Sample.find_by_name('Sam2'))
          end
        end

        context "when a 2D barcode is passed in" do
          setup do
            post :create, :study_id => @study,
                :sample_registrars => {
                  '1' => {
                    :asset_group_name => 'asset_group_0',
                    :sample_tube_attributes => { :two_dimensional_barcode => 'SI0000012345' },
                    :sample_attributes => { :name => 'Sam1' }
                  },
                  '2' => {
                    :asset_group_name => 'asset_group_0',
                    :sample_tube_attributes => { :two_dimensional_barcode => 'SI0000098765' },
                    :sample_attributes => { :name => 'Sam2' }
                  }
                }
          end

          should_respond_with :redirect
          should_change('@study.samples.count', :by => 2) { @study.samples.count }
          should_change('Asset.count', :by => 2) { Asset.count }

          context 'sample 1' do
            subject { Sample.find_by_name("Sam1") }

            should 'have the 2D barcode on the asset' do
              assert_equal "SI0000012345", subject.assets.first.two_dimensional_barcode
            end

            should 'have the barcode on the asset' do
              assert_equal "12345", subject.assets.first.barcode
            end
          end

          context 'sample 2' do
            subject { Sample.find_by_name('Sam2') }

            should 'have the 2D barcode on the asset' do
              assert_equal "SI0000098765", subject.assets.first.two_dimensional_barcode
            end

            should 'have the barcode on the asset' do
              assert_equal "98765", subject.assets.first.barcode
            end
          end
        end

        context 'when sample information is missing' do
          setup do
            post :create, :study_id => @study,
              :sample_registrars => { '1' => { } }
          end
          should_render_template :new
        end

        # TODO: samples with duplicate well IDs
        # Interface behaviour has changed slightly. We might want to reinstate this behaviour in future.
      end
    end
  end

end
