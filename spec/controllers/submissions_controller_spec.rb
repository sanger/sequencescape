# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubmissionsController, type: :controller do
  render_views

  let(:request_type) { create(:well_request_type) }

  it_behaves_like 'it requires login'

  context 'Submissions controller' do
    before do
      @user = create(:user)
      @controller = described_class.new
      @request = ActionController::TestRequest.create(@controller)

      session[:user] = @user

      # We need to specify the details of the map while using Map.find_by
      # to avoid picking up another map with the same description. As of
      # the current records, the 'description' and 'asset_size' attributes
      # can uniquely identify a map; asset_shape is added for completeness.
      @asset_shape = AssetShape.default
      @asset_size = 96

      @plate = build(:plate, barcode: 'SQPD-123456')
      %w[A1 A2 A3 B1 B2 B3 C1 C2 C3].each do |location|
        well =
          build(
            :well_with_sample_and_without_plate,
            map: Map.find_by(description: location, asset_shape: @asset_shape, asset_size: @asset_size)
          )
        @plate.wells << well
      end
      build(
        :well,
        map: Map.find_by(description: 'C5', asset_shape: @asset_shape, asset_size: @asset_size),
        plate: @plate
      )
      @plate.save
      @study = create(:study, name: 'A study')
      @project = create(:project, name: 'A project')
      submission_template_hash = {
        name: 'Cherrypicking for Pulldown',
        submission_class_name: 'LinearSubmission',
        product_catalogue: 'Generic',
        submission_parameters: {
          info_differential: 5,
          asset_input_methods: ['select an asset group', 'enter a list of sample names found on plates'],
          request_types: [request_type.key]
        }
      }
      @submission_template = SubmissionSerializer.construct!(submission_template_hash)
    end

    context 'when a submission exists' do
      before do
        @user.grant_lab_manager
        @submission = Submission.create!(priority: 1, user: @user)
        post :change_priority, params: { id: @submission.id, submission: { priority: 3 } }
      end

      it 'allow update of priorities' do
        expect(@submission.reload.priority).to eq(3)
      end
    end

    context 'when a submission exists allow admin to cancel' do
      before do
        @user.grant_administrator
        @submission = Submission.create!(priority: 1, user: @user)
        @submission.state = 'pending'
        @submission.save
        post :cancel, params: { id: @submission.id }
      end

      it 'allow admin to cancel' do
        expect(@submission.reload.state).to eq('cancelled')
      end
    end

    context 'do not allow users other than administrator, lab manager or slf manager to cancel submission' do
      before do
        @submission = Submission.create!(priority: 1, user: @user)
        @submission.state = 'pending'
        @submission.save
        post :cancel, params: { id: @submission.id }
      end

      it 'do not allow other users to cancel' do
        expect(@submission.reload.state).not_to eq('cancelled')
      end
    end

    context 'when a submission exists allow lab manager to cancel' do
      before do
        @user.grant_lab_manager
        @submission = Submission.create!(priority: 1, user: @user)
        @submission.state = 'pending'
        @submission.save
        post :cancel, params: { id: @submission.id }
      end

      it 'allow lab manager to cancel' do
        expect(@submission.reload.state).to eq('cancelled')
      end
    end

    context 'when a submission exists allow sample management manager to cancel' do
      before do
        @user.grant_slf_manager
        @submission = Submission.create!(priority: 1, user: @user)
        @submission.state = 'pending'
        @submission.save
        post :cancel, params: { id: @submission.id }
      end

      it 'allow sample management manager to cancel' do
        expect(@submission.reload.state).to eq('cancelled')
      end
    end

    # Mainly to verify that it isn't the new test that is broken
    context 'by sample name' do
      before do
        @samples = samples = Well.with_aliquots.each.map { |w| w.aliquots.first.sample.name }

        post(
          :create,
          params: {
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
          }
        )
      end

      it 'create the appropriate orders' do
        expect(Order.first.assets.count).to eq(4)
      end

      context 'with a more recent plate' do
        before do
          @new_plate = create(:plate, plate_purpose: @plate.purpose)
          @well =
            create(
              :well,
              map: Map.find_by(description: 'A1', asset_shape: @asset_shape, asset_size: @asset_size),
              plate: @new_plate
            )
          create(:aliquot, sample: Sample.find_by(name: @samples.first), receptacle: @well)
          post(
            :create,
            params: {
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
                sample_names_text: @samples[0...4].join("\n"),
                plate_purpose_id: @plate.plate_purpose.id.to_s,
                project_name: 'A project'
              }
            }
          )
        end

        it 'find the latest version' do
          per_plate = Order.last.assets.group_by(&:plate)

          # Return an empty hash if we have no hits, makes the test failures clearer.
          per_plate.default = []
          expect(per_plate[@new_plate].count).to eq(1)
          expect(per_plate[@plate].count).to eq(3)
        end
      end
    end

    context 'by sample name and working dilution' do
      before do
        @order_count = Order.count
        @wd_plate = create(:working_dilution_plate)
        %w[A1 A2 A3 B1 B2 B3 C1 C2 C3].each do |location|
          well =
            create(
              :empty_well,
              map: Map.find_by(description: location, asset_shape: @asset_shape, asset_size: @asset_size)
            )
          well.aliquots.create(sample: @plate.wells.located_at(location).first.aliquots.first.sample)
          @wd_plate.wells << well
        end
        samples = @wd_plate.wells.with_aliquots.each.map { |w| w.aliquots.first.sample.name }

        post(
          :create,
          params: {
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
              plate_purpose_id: @wd_plate.plate_purpose.id.to_s,
              project_name: 'A project'
            }
          }
        )
      end

      it 'used the working dilution plate' do
        expect(Order.count - @order_count).to eq(1)

        wells = Order.last.assets

        expect(wells.size).to eq(4)
        wells.each { |well| expect(@wd_plate.wells.include?(well)).to be(true) }
      end
    end

    context 'by plate barcode' do
      before do
        @order_count = Order.count
        post :create, params: plate_submission('SQPD-123456')
      end

      it 'create the appropriate orders' do
        assert Order.first.present?, 'No order was created!'
        expect(Order.first.assets.count).to eq(9)
      end
    end

    context 'by plate barcode with pools' do
      before do
        @plate.wells.first.aliquots.create!(sample: create(:sample), tag_id: Tag.first.id)
        post :create, params: plate_submission('SQPD-123456')
      end

      it 'create the appropriate orders' do
        expect(Order.first.assets.count).to eq(9)
      end
    end

    context 'it allow submission by plate barcode and wells' do
      before { post :create, params: plate_submission('SQPD-123456:A1,B3,C2') }

      it 'create the appropriate orders' do
        expect(Order.first.assets.count).to eq(3)
      end
    end

    context 'it allow submission by plate barcode and rows' do
      before { post :create, params: plate_submission('SQPD-123456:B,C') }

      it 'create the appropriate orders' do
        expect(Order.first.assets.count).to eq(6)
      end
    end

    context 'it allow submission by plate barcode and columns' do
      before { post :create, params: plate_submission('SQPD-123456:1,2,3') }

      it 'create the appropriate orders' do
        expect(Order.first.assets.count).to eq(9)
      end
    end

    context 'A submission with clashing orders' do
      before do
        @shared_template = 'shared_template'
        @sample = create(:sample)
        @asset_a = create(:sample_tube, sample: @sample)
        @asset_b = create(:sample_tube, sample: @sample)
        @secondary_submission = create(:submission)
        @secondary_order =
          create(
            :order,
            assets: [@asset_b.receptacle],
            template_name: @shared_template,
            submission: @secondary_submission
          )
        @submission = create(:submission)
        @order = create(:order, assets: [@asset_a.receptacle], template_name: @shared_template, submission: @submission)
      end

      it 'warn the user about duplicates' do
        get :show, params: { id: @submission.id }
        assert_select 'div.alert-submission_warning' do
          assert_select 'h4', 'Warning! Similar submissions detected'
          assert_select 'li.sample', 1
          assert_select 'li.submission', 1
        end
      end
    end

    context 'A submission with not ready samples' do
      before do
        @shared_template = 'shared_template'
        sample_manifest = create(:tube_sample_manifest_with_samples)
        @samples_names = sample_manifest.samples.map(&:name).join(', ')
        @submission = create(:submission)
        @order =
          create(:order, assets: sample_manifest.labware, template_name: @shared_template, submission: @submission)
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
      before do
        @shared_template = 'shared_template'
        @sample = create(:sample)
        @asset_a = create(:sample_tube, sample: @sample)
        @submission = create(:submission)
        @order = create(:order, assets: [@asset_a.receptacle], template_name: @shared_template, submission: @submission)
      end

      it 'not warn the user about duplicates or samples' do
        get :show, params: { id: @submission.id }
        assert_select 'div.alert-danger', 0
      end
    end

    describe '#download_scrna_core_cdna_pooling_plan' do
      before do
        @template = create(:submission_template, name: 'Limber-Htp - scRNA Core cDNA Prep GEM-X 5p')
        @study = create(:study, user: @user)
        @project = create(:project)
        submission_order = create(:order_with_submission, template_name: @template.name, study: @study,
                                                          project: @project,
                                                          user: @user,
                                                          asset_group: create(:asset_group, study: @study))
        @submission = submission_order.submission
      end

      it 'downloads a pooling plan' do
        get :download_scrna_core_cdna_pooling_plan, params: { id: @submission.id }

        expect(response.headers['Content-Disposition']).to include("#{@submission.id}_scrna_core_cdna_pooling_plan.csv")
      end
    end
  end

  def plate_submission(text)
    {
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
        sample_names_text: '',
        barcodes_wells_text: text,
        plate_purpose_id: @plate.plate_purpose.id.to_s,
        project_name: 'A project'
      }
    }
  end
end
