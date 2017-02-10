# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2012,2013,2015 Genome Research Ltd.

require 'test_helper'
require 'submissions_controller'

class SubmissionsControllerTest < ActionController::TestCase
  context 'Submissions controller' do
    setup do
      @user       = create :user
      @controller = SubmissionsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new

      session[:user] = @user

      @plate = build :plate, barcode: 123456
      %w(
A1 A2 A3
B1 B2 B3
C1 C2 C3
).each do |location|
        well = build :well_with_sample_and_without_plate, map: Map.find_by(description: location)
        @plate.wells << well
      end
      build(:well, map: Map.find_by(description: 'C5'), plate: @plate)
      @plate.save
      @study = create :study, name: 'A study'
      @project = create :project, name: 'A project'
      @submission_template = SubmissionTemplate.find_by!(name: 'Cherrypicking for pulldown')
    end

    context 'when a submission exists' do
      setup do
        @user.is_lab_manager
        @submission = Submission.create!(priority: 1, user: @user)
        post :change_priority, id: @submission.id, submission: { priority: 3 }
      end

      should 'allow update of priorities' do
        assert_equal 3, @submission.reload.priority
      end
    end

    should_require_login

    # Mainly to verify that it isn't the new test that is broken
    context 'by sample name' do
      setup do
        @samples = samples = Well.with_aliquots.each.map { |w| w.aliquots.first.sample.name }

        post(:create,
          submission: {
            is_a_sequencing_order: 'false',
            comments: '',
            template_id: @submission_template.id.to_s,
            order_params: {
              'read_length' => '37',
              'fragment_size_required_to' => '400',
              'bait_library_name' => 'Human all exon 50MB',
              'fragment_size_required_from' => '100',
              'library_type' => 'Agilent Pulldown' },
            asset_group_id: '',
            study_id: @study.id.to_s,
            sample_names_text: samples[1..4].join("\n"),
            plate_purpose_id: @plate.plate_purpose.id.to_s,
            project_name: 'A project'
          }
        )
      end

      should 'create the appropriate orders' do
        assert_equal 4, Order.first.assets.count
      end

      context 'with a more recent plate' do
        setup do
          @new_plate = FactoryGirl.create :plate, plate_purpose: @plate.purpose
          @well = create :well, map: Map.find_by(description: 'A1'), plate: @new_plate
          create(:aliquot, sample: Sample.find_by(name: @samples.first), receptacle: @well)
          post(:create, submission: {
            is_a_sequencing_order: 'false',
            comments: '',
            template_id: @submission_template.id.to_s,
            order_params: {
              'read_length' => '37', 'fragment_size_required_to' => '400',
              'bait_library_name' => 'Human all exon 50MB',
              'fragment_size_required_from' => '100', 'library_type' => 'Agilent Pulldown' },
            asset_group_id: '',
            study_id: @study.id.to_s,
            sample_names_text: @samples[0...4].join("\n"),
            plate_purpose_id: @plate.plate_purpose.id.to_s, project_name: 'A project' })
        end

        should 'find the latest version' do
          per_plate = Order.last.assets.group_by(&:plate)
          # Return an empty hash if we have no hits, makes the test failures clearer.
          per_plate.default = []
          assert_equal 1, per_plate[@new_plate].count
          assert_equal 3, per_plate[@plate].count
        end
      end
    end

    context 'by sample name and working dilution' do
      setup do
        @order_count = Order.count
        @wd_plate = create :working_dilution_plate, barcode: 123457
        %w(
A1 A2 A3
B1 B2 B3
C1 C2 C3
).each do |location|
        well = create :empty_well, map: Map.find_by(description: location)
          well.aliquots.create(sample: @plate.wells.located_at(location).first.aliquots.first.sample)
          @wd_plate.wells << well
        end
        samples = @wd_plate.wells.with_aliquots.each.map { |w| w.aliquots.first.sample.name }

        post(:create, submission: {
          is_a_sequencing_order: 'false',
          comments: '',
          template_id: @submission_template.id.to_s,
          order_params: {
            'read_length' => '37',
            'fragment_size_required_to' => '400',
            'bait_library_name' => 'Human all exon 50MB',
            'fragment_size_required_from' => '100',
            'library_type' => 'Agilent Pulldown'
          },
          asset_group_id: '',
          study_id: @study.id.to_s,
          sample_names_text: samples[1..4].join("\n"),
          plate_purpose_id: @wd_plate.plate_purpose.id.to_s,
          project_name: 'A project' })
      end

      should 'used the working dilution plate' do
        assert_equal 1, Order.count - @order_count
        assert_equal @wd_plate, Order.last.assets.first.plate
      end
    end

    context 'by plate barcode' do
      setup do
         @order_count = Order.count
        post :create, plate_submission('DN123456P')
      end

      should 'create the appropriate orders' do
        assert Order.first.present?, 'No order was created!'
        assert_equal 9, Order.first.assets.count
      end
    end

    context 'by plate barcode with pools' do
      setup do
        @plate.wells.first.aliquots.create!(sample: FactoryGirl.create(:sample), tag_id: Tag.first.id)
        post :create, plate_submission('DN123456P')
      end

      should 'create the appropriate orders' do
        assert_equal 9, Order.first.assets.count
      end
    end

    context 'should allow submission by plate barcode and wells' do
      setup do
        post :create, plate_submission('DN123456P:A1,B3,C2')
      end

      should 'create the appropriate orders' do
        assert_equal 3, Order.first.assets.count
      end
    end

    context 'should allow submission by plate barcode and rows' do
      setup do
        post :create, plate_submission('DN123456P:B,C')
      end

      should 'create the appropriate orders' do
        assert_equal 6, Order.first.assets.count
      end
    end

    context 'should allow submission by plate barcode and columns' do
      setup do
        post :create, plate_submission('DN123456P:1,2,3')
      end

      should 'create the appropriate orders' do
        assert_equal 9, Order.first.assets.count
      end
    end

    context 'A submission with clashing orders' do
      setup do
        @shared_template = 'shared_template'
        @sample  = create :sample
        @asset_a = create :sample_tube, sample:  @sample
        @asset_b = create :sample_tube, sample:  @sample
        @secondary_submission = create :submission
        @secondary_order = create :order, assets: [@asset_b], template_name: @shared_template, submission: @secondary_submission
        @submission = create :submission
        @order = create :order, assets: [@asset_a], template_name: @shared_template, submission: @submission
      end

      should 'warn the user about duplicates' do
        get :show, id: @submission.id
        assert_select 'div.alert-danger' do
          assert_select 'strong', 'Warning! Similar submissions detected'
          assert_select 'li.sample', 1
          assert_select 'li.submission', 1
        end
      end
    end

    context 'A submission without clashing orders' do
      setup do
        @shared_template = 'shared_template'
        @sample  = create :sample
        @asset_a = create :sample_tube, sample: @sample
        @submission = create :submission
        @order = create :order, assets: [@asset_a], template_name: @shared_template, submission: @submission
      end

      should 'not warn the user about duplicates' do
        get :show, id: @submission.id
        assert_select 'div.alert-danger', 0
      end
    end
  end

  def plate_submission(text)
    { submission: {
      is_a_sequencing_order: 'false',
      comments: '',
      template_id: @submission_template.id.to_s,
      order_params: {
        'read_length' => '37',
        'fragment_size_required_to' => '400',
        'bait_library_name' => 'Human all exon 50MB',
        'fragment_size_required_from' => '100',
        'library_type' => 'Agilent Pulldown' },
      asset_group_id: '',
      study_id: @study.id.to_s,
      sample_names_text: '',
      barcodes_wells_text: text,
      plate_purpose_id: @plate.plate_purpose.id.to_s,
      project_name: 'A project' }
    }
  end
end
