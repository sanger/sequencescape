# frozen_string_literal: true

require 'test_helper'

class SamplesControllerTest < ActionController::TestCase
  context 'Samples controller' do
    setup do
      @controller = SamplesController.new
      @request = ActionController::TestRequest.create(@controller)

      Sample.stubs(:assets).returns([])
    end

    should_require_login

    resource_test(
      'sample',
      defaults: {
        name: 'Sample22',
        sample_metadata_attributes: {
          cohort: 'Cohort',
          gender: 'Male',
          genotype: '',
          phenotype: ''
        }
      },
      formats: ['html'],
      ignore_actions: %w[show create destroy],
      protect_on_update: [:name],
      extra_on_update: {
        sample_metadata_attributes: {
          check: {
            genotype: 'false',
            phenotype: 'true'
          }
        }
      },
      user: :admin
    )

    # TODO: Test without admin
    context 'when logged in' do
      setup do
        @user = FactoryBot.create(:user)
        @controller.stubs(:logged_in?).returns(@user)
        session[:user] = @user.id
      end

      context '#add_to_study' do
        setup do
          @initial_study_sample_count = StudySample.count
          @sample = FactoryBot.create(:sample)
          @study = FactoryBot.create(:study)
          put :add_to_study, params: { id: @sample.id, study: { id: @study.id } }
        end
        should 'change StudySample.count from  0 to 1' do
          assert_equal 0, @initial_study_sample_count
          assert_equal 1, StudySample.count
        end
        should redirect_to('sample path') { sample_path(@sample) }
      end

      context '#move' do
      end
    end
  end
end
