# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015,2016 Genome Research Ltd.

require 'test_helper'
require 'studies_controller'

class StudiesControllerTest < ActionController::TestCase
  context 'StudiesController' do
    setup do
      @controller = StudiesController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
    end

    should_require_login

    resource_test(
      'study',         defaults: { name: 'study name' },
                       user: :admin,
                       other_actions: ['properties', 'study_status'],
                       ignore_actions: %w(show create update destroy),
                       formats: ['xml']
    )
  end

  context 'create a study - custom' do
    setup do
      @controller = StudiesController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
      @user = FactoryGirl.create(:user)
      @user.has_role('owner')
      @controller.stubs(:logged_in?).returns(@user)
      session[:user] = @user.id
    end

    context '#new' do
      setup do
        get :new
      end

      should respond_with :success
      should render_template :new
    end

    context '#create' do
      setup do
        @request_type_1 = FactoryGirl.create :request_type
        @program = FactoryGirl.create :program
      end

      context 'successfullyFactoryGirl.create a new study' do
        setup do
          @study_count = Study.count
          post :create, 'study' => {
            'name' => 'hello',
            'reference_genome_id' => ReferenceGenome.find_by(name: '').id,
            'study_metadata_attributes' => {
              'faculty_sponsor_id' => FacultySponsor.create!(name: 'Me'),
              'study_description' => 'some new study',
              'program_id' => @program.name,
              'contains_human_dna' => 'No',
              'contaminated_human_dna' => 'No',
              'commercially_available' => 'No',
              'data_release_study_type_id' => DataReleaseStudyType.find_by(name: 'genomic sequencing'),
              'data_release_strategy' => 'open',
              'study_type_id' => StudyType.find_by(name: 'Not specified').id
            }
          }
        end

        should set_flash.to('Your study has been created')
        should redirect_to('study path') { study_path(Study.last) }
        should 'change Study.count by 1' do
          assert_equal 1, Study.count - @study_count
        end
      end

      context 'fail to create a new study' do
        setup do
          @initial_study_count = Study.count
          post :create, 'study' => { 'name' => 'hello 2' }
        end

        should render_template :new

        should 'not change Study.count' do
          assert_equal @initial_study_count, Study.count
        end

        should set_flash.now.to('Problems creating your new study')
      end

      context 'create a new study with a program specified' do
        setup do
          # Program.new(:name => 'testing program').save
          post :create, 'study' => {
            'name' => 'hello 4',
            'reference_genome_id' => ReferenceGenome.find_by(name: '').id,
            'study_metadata_attributes' => {
              'faculty_sponsor_id' => FacultySponsor.create!(name: 'Me').id,
              'study_description' => 'some new study',
              'contains_human_dna' => 'No',
              'program_id' => @program.id,
              'contaminated_human_dna' => 'No',
              'commercially_available' => 'No',
              'data_release_study_type_id' => DataReleaseStudyType.find_by(name: 'genomic sequencing').id,
              'data_release_strategy' => 'open',
              'study_type_id' => StudyType.find_by(name: 'Not specified').id
            }
          }
        end
        should 'create a study with a new program' do
          assert_equal Study.find_by(name: 'hello 4').study_metadata.program.name, @program.name
        end
      end
      context 'creating a new study without program' do
        setup do
          @study_count = Study.count
          post :create, 'study' => {
            'name' => 'hello 4',
            'reference_genome_id' => ReferenceGenome.find_by(name: '').id,
            'study_metadata_attributes' => {
              'faculty_sponsor_id' => FacultySponsor.create!(name: 'Me').id,
              'study_description' => 'some new study',
              'contains_human_dna' => 'No',
              'contaminated_human_dna' => 'No',
              'commercially_available' => 'No',
              'data_release_study_type_id' => DataReleaseStudyType.find_by(name: 'genomic sequencing').id,
              'data_release_strategy' => 'open',
              'study_type_id' => StudyType.find_by(name: 'Not specified').id
            }
          }
        end
        should 'fail on trying to create the study' do
          assert_equal  Study.count, @study_count
        end
      end

      context 'create a new study using permission allowed (not required)' do
        setup do
          @study_count = Study.count
          post :create, 'study' => {
            'name' => 'hello 3',
            'reference_genome_id' => ReferenceGenome.find_by(name: '').id,
            'study_metadata_attributes' => {
              'faculty_sponsor_id' => FacultySponsor.create!(name: 'Me').id,
              'study_description' => 'some new study',
              'contains_human_dna' => 'No',
              'program_id' => @program.id,
              'contaminated_human_dna' => 'No',
              'commercially_available' => 'No',
              'data_release_study_type_id' => DataReleaseStudyType.find_by(name: 'genomic sequencing').id,
              'data_release_strategy' => 'open',
              'study_type_id' => StudyType.find_by(name: 'Not specified').id
            }
          }
        end

        should 'change Study.count by 1' do
          assert_equal 1, Study.count - @study_count
        end
        should redirect_to('study path') { study_path(Study.last) }
        should set_flash.to('Your study has been created')
      end
    end
  end
end
