# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2013,2014,2015 Genome Research Ltd.

require 'test_helper'
require 'samples_controller'

class SamplesControllerTest < ActionController::TestCase
  context 'Samples controller' do
    setup do
      @controller = SamplesController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new

      Sample.stubs(:assets).returns([])
    end

    should_require_login

    resource_test(
      'sample', defaults: {
          name: 'Sample22',
          sample_metadata_attributes: {
             cohort: 'Cohort',
             gender: 'Male',
             genotype: '',
             phenotype: '',
             reference_genome_id: FactoryGirl.create(:reference_genome).id
            }
        },
                formats: ['html'],
                ignore_actions: %w(show create destroy),
                protect_on_update: [:name],
                extra_on_update: { sample_metadata_attributes: { check: { genotype: 'false', phenotype: 'true' } } },
                user: -> { user = FactoryGirl.create(:user); user.is_administrator; user }
    )

    # TODO: Test without admin
    context 'when logged in' do
      setup do
        @user = FactoryGirl.create :user
        @controller.stubs(:logged_in?).returns(@user)
        session[:user] = @user.id
      end

      context '#add_to_study' do
        setup do
          @initial_study_sample_count = StudySample.count
          @sample = FactoryGirl.create :sample
          @study = FactoryGirl.create :study
          put :add_to_study, id: @sample.id, study: { id: @study.id }
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
