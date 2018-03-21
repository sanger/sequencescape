# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubmissionsController, type: :controller do
  render_views

  it_behaves_like 'it requires login'

  context 'Submissions controller' do
    setup do
      @user       = create :user
      @controller = SubmissionsController.new
      @request    = ActionController::TestRequest.create(@controller)

      session[:user] = @user

      @plate = build :plate, barcode: 123456
      %w[
        A1 A2 A3
        B1 B2 B3
        C1 C2 C3
      ].each do |location|
        well = build :well_with_sample_and_without_plate, map: Map.find_by(description: location)
        @plate.wells << well
      end
      build(:well, map: Map.find_by(description: 'C5'), plate: @plate)
      @plate.save
      @study = create :study, name: 'A study'
      @project = create :project, name: 'A project'
      submission_template_hash = { name: 'Cherrypicking for Pulldown',
                                   submission_class_name: 'LinearSubmission',
                                   product_catalogue: 'Generic',
                                   submission_parameters: { info_differential: 5,
                                                            asset_input_methods: ['select an asset group', 'enter a list of sample names found on plates'],
                                                            request_types: ['cherrypick_for_pulldown'] } }
      @submission_template = SubmissionSerializer.construct!(submission_template_hash)
    end

    context 'when a submission exists' do
      setup do
        @user.is_lab_manager
        @submission = Submission.create!(priority: 1, user: @user)
        post :change_priority, params: { id: @submission.id, submission: { priority: 3 } }
      end

      it 'allow update of priorities' do
        assert_equal 3, @submission.reload.priority
      end
    end

    # Mainly to verify that it isn't the new test that is broken
    context 'by sample name' do
      setup do
        @samples = samples = Well.with_aliquots.each.map { |w| w.aliquots.first.sample.name }

        post(:create, params: {
               submission: {
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
                 plate_purpose_id: @plate.plate_purpose.id.to_s,
                 project_name: 'A project'
               }
             })
      end

      it 'create the appropriate orders' do
        assert_equal 4, Order.first.assets.count
      end

      context 'with a more recent plate' do
        setup do
          @new_plate = FactoryGirl.create :plate, plate_purpose: @plate.purpose
          @well = create :well, map: Map.find_by(description: 'A1'), plate: @new_plate
          create(:aliquot, sample: Sample.find_by(name: @samples.first), receptacle: @well)
          post(:create, params: { submission: {
                 is_a_sequencing_order: 'false',
                 comments: '',
                 template_id: @submission_template.id.to_s,
                 order_params: {
                   'read_length' => '37', 'fragment_size_required_to' => '400',
                   'bait_library_name' => 'Human all exon 50MB',
                   'fragment_size_required_from' => '100', 'library_type' => 'Agilent Pulldown'
                 },
                 asset_group_id: '',
                 study_id: @study.id.to_s,
                 sample_names_text: @samples[0...4].join("\n"),
                 plate_purpose_id: @plate.plate_purpose.id.to_s, project_name: 'A project'
               } })
        end

        it 'find the latest version' do
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
        %w[
          A1 A2 A3
          B1 B2 B3
          C1 C2 C3
        ].each do |location|
          well = create :empty_well, map: Map.find_by(description: location)
          well.aliquots.create(sample: @plate.wells.located_at(location).first.aliquots.first.sample)
          @wd_plate.wells << well
        end
        samples = @wd_plate.wells.with_aliquots.each.map { |w| w.aliquots.first.sample.name }

        post(:create, params: { submission: {
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
               project_name: 'A project'
             } })
      end

      it 'used the working dilution plate' do
        assert_equal 1, Order.count - @order_count
        assert_equal @wd_plate, Order.last.assets.first.plate
      end
    end

    context 'by plate barcode' do
      setup do
        @order_count = Order.count
        post :create, params: plate_submission('DN123456P')
      end

      it 'create the appropriate orders' do
        assert Order.first.present?, 'No order was created!'
        assert_equal 9, Order.first.assets.count
      end
    end

    context 'by plate barcode with pools' do
      setup do
        @plate.wells.first.aliquots.create!(sample: FactoryGirl.create(:sample), tag_id: Tag.first.id)
        post :create, params: plate_submission('DN123456P')
      end

      it 'create the appropriate orders' do
        assert_equal 9, Order.first.assets.count
      end
    end

    context 'it allow submission by plate barcode and wells' do
      setup do
        post :create, params: plate_submission('DN123456P:A1,B3,C2')
      end

      it 'create the appropriate orders' do
        assert_equal 3, Order.first.assets.count
      end
    end

    context 'it allow submission by plate barcode and rows' do
      setup do
        post :create, params: plate_submission('DN123456P:B,C')
      end

      it 'create the appropriate orders' do
        assert_equal 6, Order.first.assets.count
      end
    end

    context 'it allow submission by plate barcode and columns' do
      setup do
        post :create, params: plate_submission('DN123456P:1,2,3')
      end

      it 'create the appropriate orders' do
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

      it 'warn the user about duplicates' do
        get :show, params: { id: @submission.id }
        assert_select 'div.alert-danger' do
          assert_select 'strong', 'Warning! Similar submissions detected'
          assert_select 'li.sample', 1
          assert_select 'li.submission', 1
        end
      end
    end

    context 'A submission with not ready samples' do
      setup do
        @shared_template = 'shared_template'
        sample_manifest = create :tube_sample_manifest_with_samples
        @samples_names = sample_manifest.samples.map(&:name).join(', ')
        @submission = create :submission
        @order = create :order, assets: sample_manifest.labware, template_name: @shared_template, submission: @submission
      end

      it 'warn the user about not ready samples' do
        get :show, params: { id: @submission.id }
        assert_select 'div.alert-danger' do
          assert_select 'strong', 'Warning! Some samples might not be suitable for this submission'
          assert_select 'p', "Samples #{@samples_names} might not have all required metadata"
        end
      end
    end

    context 'A submission without warnings' do
      setup do
        @shared_template = 'shared_template'
        @sample  = create :sample
        @asset_a = create :sample_tube, sample: @sample
        @submission = create :submission
        @order = create :order, assets: [@asset_a], template_name: @shared_template, submission: @submission
      end

      it 'not warn the user about duplicates or samples' do
        get :show, params: { id: @submission.id }
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
        'library_type' => 'Agilent Pulldown'
      },
      asset_group_id: '',
      study_id: @study.id.to_s,
      sample_names_text: '',
      barcodes_wells_text: text,
      plate_purpose_id: @plate.plate_purpose.id.to_s,
      project_name: 'A project'
    } }
  end
end
