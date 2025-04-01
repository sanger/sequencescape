# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LinearSubmission do
  let(:mx_asset_count) { 5 }
  let(:sx_asset_count) { 5 }

  let(:study) { create(:study) }
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  describe 'build (Submission factory)' do
    let(:sequencing_request_type) { create(:sequencing_request_type) }
    let(:purpose) { create(:std_mx_tube_purpose) }
    let(:request_options) do
      { 'read_length' => '108', 'fragment_size_required_from' => '150', 'fragment_size_required_to' => '200' }
    end

    context 'when a multiplexed submission' do
      describe 'Customer decision propagation' do
        let(:library_creation_request_type) do
          create(:well_request_type, :with_library_types, target_purpose: purpose, for_multiplexing: true)
        end
        let(:product_criteria) { create(:product_criteria) }
        let(:current_report) { create(:qc_report, product_criteria:) }
        let(:stock_well) { create(:well) }
        let(:request_well) do
          well = create(:well)
          well.stock_wells.attach!([stock_well])
          well.reload
          well
        end
        let(:expected_metric) do
          create(
            :qc_metric,
            asset: stock_well,
            qc_report: current_report,
            qc_decision: 'manually_failed',
            proceed: true
          )
        end
        let(:mpx_submission) do
          create(
            :linear_submission,
            study: study,
            project: project,
            user: user,
            request_types: [library_creation_request_type.id, sequencing_request_type.id],
            request_options: request_options,
            product: product_criteria.product,
            assets: [request_well]
          ).submission
        end

        before do
          expected_metric
          mpx_submission.built!
        end

        it 'set an appropriate criteria and set responsibility' do
          mpx_submission.process!
          mpx_submission.requests.each do |request|
            assert request.qc_metrics.include?(expected_metric),
                   "Metric not included in #{request.request_type.name}: #{request.qc_metrics.inspect}"
            expect(request.request_metadata.customer_accepts_responsibility).to(
              be(true),
              "Customer doesn't accept responsibility"
            )
          end
        end
      end

      context 'with basic behaviour' do
        let(:mpx_assets) { create_list(:sample_tube, mx_asset_count) }
        let(:library_creation_request_type) do
          create(:multiplexed_library_creation_request_type, target_purpose: purpose)
        end
        let(:mpx_submission) do
          create(
            :linear_submission,
            study: study,
            project: project,
            user: user,
            assets: mpx_assets,
            request_types: request_type_option,
            request_options: request_options
          ).submission
        end

        before { mpx_submission.built! }

        describe '#process!' do
          context 'when library_creation then sequencing' do
            let(:request_type_option) { [library_creation_request_type.id, sequencing_request_type.id] }

            it 'create requests but not comments' do
              # rubocop:todo RSpec/ChangeByZero
              expect { mpx_submission.process! }.to change(Request, :count).by(mx_asset_count + 1).and change(
                      Comment,
                      :count
                    ).by(0)
              # rubocop:enable RSpec/ChangeByZero
            end

            it 'be a multiplexed submission' do
              expect(mpx_submission).to be_multiplexed
            end

            it "not save a comment if one isn't supplied" do
              expect(mpx_submission.comments).to be_blank
            end
          end

          context 'when multiple requests after plexing' do
            let(:sequencing_request_type_2) { create(:sequencing_request_type) }
            let(:request_type_option) do
              [library_creation_request_type.id, sequencing_request_type_2.id, sequencing_request_type.id]
            end

            it 'create requests but not comments' do
              # rubocop:todo RSpec/ChangeByZero
              expect { mpx_submission.process! }.to change(Request, :count).by(mx_asset_count + 2).and change(
                      Comment,
                      :count
                    ).by(0)
              # rubocop:enable RSpec/ChangeByZero
            end
          end
        end
      end
    end

    context 'with two stages of library creation' do
      let(:library_creation_stage1) { create(:library_request_type, :with_library_types) }
      let(:library_creation_stage2) { create(:library_request_type, :with_library_types) }
      let(:mx_request_type) { create(:multiplex_request_type) }
      let(:request_type_option) do
        [library_creation_stage1.id, library_creation_stage2.id, mx_request_type.id, sequencing_request_type.id]
      end
      let(:assets) { create_list(:untagged_well, 2) }
      let(:basic_options) do
        {
          study: study,
          project: project,
          user: user,
          request_types: request_type_option,
          request_options: request_options,
          assets: assets
        }
      end
      let(:submission) { create(:linear_submission, basic_options).submission.tap(&:built!) }

      it 'builds the submission' do
        submission.process!
        expect(library_creation_stage1.requests.count).to eq(2)
        expect(library_creation_stage2.requests.count).to eq(2)
        expect(sequencing_request_type.requests.count).to eq(1)
      end
    end

    context 'when a single-plex submission' do
      let(:assets) { (1..sx_asset_count).map { |i| create(:sample_tube, name: "Asset#{i}") } }
      let(:library_creation_request_type) { create(:library_creation_request_type, :with_library_types) }
      let(:request_type_option) { [library_creation_request_type.id, sequencing_request_type.id] }
      let(:submission) do
        create(
          :linear_submission,
          study: study,
          project: project,
          user: user,
          assets: assets,
          request_types: request_type_option,
          request_options: request_options,
          comments: 'This is a comment'
        ).submission
      end

      before { submission.built! }

      it 'not be a multiplexed submission' do
        expect(submission.multiplexed?).to be false
      end

      it 'save request_types as array of Integers' do
        expect(submission.orders.first.request_types).to be_a Array
        expect(submission.orders.first.request_types).to eq(request_type_option)
      end

      it "save a comment if there's one passed in" do
        expect(submission.comments).to eq(['This is a comment'])
      end

      describe '#process!' do
        it 'create requests but not comments' do
          expect { submission.process! }.to change(Request, :count).by(sx_asset_count * 2).and change(
                  Comment,
                  :count
                ).by(sx_asset_count * 2)
        end

        context 'when it has been run' do
          before { submission.process! }

          let(:library_request) { submission.requests.find_by!(request_type_id: library_creation_request_type.id) }
          let(:sequencing_request) { submission.requests.find_by!(request_type_id: sequencing_request_type.id) }

          it 'assign submission ids to the requests' do
            expect(submission.requests.first.submission).to eq(submission)
          end

          it 'sets metadata on library creation requests' do
            expect(library_request.request_metadata).to have_attributes(
              customer_accepts_responsibility: nil,
              gigabases_expected: nil,
              library_type: library_creation_request_type.default_library_type.name,
              fragment_size_required_to: '200',
              fragment_size_required_from: '150'
            )
          end

          it 'sets metadata on sequencing requests' do
            expect(sequencing_request.request_metadata).to have_attributes(
              customer_accepts_responsibility: nil,
              read_length: 108
            )
          end
        end
      end
    end
  end

  context 'when we have a multiplier for request type' do
    let(:assets) { create_list(:sample_tube, 2) }
    let(:mx_request_type) do
      create(
        :multiplexed_library_creation_request_type,
        asset_type: 'SampleTube',
        target_asset_type: 'LibraryTube',
        initial_state: 'pending',
        name: 'Multiplexed Library Creation',
        order: 1,
        key: 'multiplexed_library_creation'
      )
    end
    let(:lib_request_type) do
      create(
        :library_creation_request_type,
        :with_library_types,
        asset_type: 'SampleTube',
        target_asset_type: 'LibraryTube',
        initial_state: 'pending',
        name: 'Library Creation',
        order: 1,
        key: 'library_creation'
      )
    end
    let(:sequencing_request_type) do
      create(
        :request_type,
        asset_type: 'LibraryTube',
        initial_state: 'pending',
        name: 'PE sequencing',
        order: 2,
        key: 'pe_sequencing'
      )
    end

    context 'when a multiplication factor of 5 is provided' do
      context 'with non multiplexed libraries and sequencing' do
        let(:submission) do
          create(
            :linear_submission,
            study: study,
            project: project,
            user: user,
            assets: assets,
            request_types: [lib_request_type.id, sequencing_request_type.id],
            request_options: {
              :multiplier => {
                sequencing_request_type.id.to_s => '5',
                lib_request_type.id.to_s => '1'
              },
              'read_length' => '108',
              'fragment_size_required_from' => '150',
              'fragment_size_required_to' => '200'
            },
            comments: ''
          ).submission
        end

        before { submission.built! }

        it 'builds the requests' do
          expect { submission.process! }.to change(Request, :count).by(12) &
            change { lib_request_type.requests.count }.by(2) & change { sequencing_request_type.requests.count }.by(10)
        end
      end

      context 'with multiplexed libraries and sequencing' do
        let(:submission) do
          create(
            :linear_submission,
            study: study,
            project: project,
            user: user,
            assets: assets,
            request_types: [mx_request_type.id, sequencing_request_type.id],
            request_options: {
              :multiplier => {
                sequencing_request_type.id.to_s => '5',
                mx_request_type.id.to_s => '1'
              },
              'read_length' => '108',
              'fragment_size_required_from' => '150',
              'fragment_size_required_to' => '200'
            },
            comments: ''
          ).submission
        end

        before { submission.built! }

        it 'builds the requests' do
          expect { submission.process! }.to change(Request, :count).by(7) &
            change { mx_request_type.requests.count }.by(2) & change { sequencing_request_type.requests.count }.by(5)
        end
      end
    end
  end

  # This covers the case of bulk submission for the template `pbmc_pooling_customer_request_type`.
  # The allowance band is calculated within the bulk submission, added to the `request_options`,
  # and transferred to the linear submission to create the corresponding requests.
  # The allowance band is defined directly into the request class `pbmc_pooling_customer_request_type` as
  # it does not require a user input.
  context 'when the submission template computes extra metadata' do
    let(:assets) { (1..sx_asset_count).map { |i| create(:sample_tube, name: "Asset#{i}") } }
    let!(:request_type) { create(:pbmc_pooling_customer_request_type) }
    let(:submission) do
      create(
        :linear_submission,
        study: study,
        project: project,
        user: user,
        assets: assets,
        request_types: [request_type.id],
        request_options: {
          'allowance_band' => 'Full allowance',
          'cells_per_chip_well' => '90000',
          'number_of_pools' => '1'
        },
        comments: 'This is a comment'
      ).submission
    end

    before do
      submission.built!
      submission.process!
    end

    it 'adds the calculated metadata to the order request_options' do
      expect(submission.requests.first.order.request_options).to have_key('allowance_band')
    end
  end
end
