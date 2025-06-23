# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Request do
  let(:study) { create(:study) }
  let(:project) { create(:project) }
  let(:submission) { create(:submission) }
  let(:order1) { create(:order, study:, project:, submission:) }
  let(:order2) { create(:order, study:, project:, submission:) }
  let(:order3) { create(:order, study:, project:, submission:) }
  let(:order4) { create(:order_with_submission, study:, project:) }

  describe '#for_order_including_submission_based_requests' do
    before do
      @sequencing_request = create(:request_with_sequencing_request_type, submission:)
      @request = create(:request, order: order1, submission: submission, asset: @asset)
      @request2 = create(:request, order: order2, submission: submission)

      @request3 = create(:request, order: order4, submission: order4.submission)
      @sequencing_request2 = create(:request_with_sequencing_request_type, submission: order4.submission)
    end

    it 'the sequencing requests are included' do
      expect(order1.requests.length).to eq 1
      expect(order2.requests.length).to eq 1
      expect(order3.requests.length).to eq 0
      expect(submission.requests.length).to eq 3
      expect(submission.requests.for_order_including_submission_based_requests(order1).length).to eq 2
      expect(submission.requests.for_order_including_submission_based_requests(order2).length).to eq 2
    end

    it 'an order without requests should at least find the sequencing requests' do
      expect(submission.requests.for_order_including_submission_based_requests(order3).length).to eq 1
    end

    # rubocop:todo Layout/LineLength
    it 'when filtering from submission and scoping with an order of another submission, none of the requests are included' do
      # rubocop:enable Layout/LineLength
      expect(order4.submission.requests.for_order_including_submission_based_requests(order1).length).to eq 0
      expect(order4.submission.requests.for_order_including_submission_based_requests(order2).length).to eq 0
      expect(order4.submission.requests.for_order_including_submission_based_requests(order3).length).to eq 0
      expect(submission.requests.for_order_including_submission_based_requests(order4).length).to eq 0
    end

    it 'requests from other submission behave independently' do
      expect(order4.requests.length).to eq 1
      expect(order4.submission.requests.length).to eq 2
      expect(order4.submission.requests.for_order_including_submission_based_requests(order4).length).to eq 2
    end

    it 'can be used as any other request scope' do
      expect(described_class.for_order_including_submission_based_requests(order1).length).to eq 2
      expect(described_class.for_order_including_submission_based_requests(order2).length).to eq 2
      expect(described_class.for_order_including_submission_based_requests(order3).length).to eq 1
      expect(described_class.for_order_including_submission_based_requests(order4).length).to eq 2
    end
  end

  describe '#next_request' do
    before do
      @genotyping_request_type = create(:request_type, name: 'genotyping')
      @cherrypick_request_type = create(:request_type, name: 'cherrypick', target_asset_type: nil)
      @submission =
        FactoryHelp.submission(
          request_types: [@cherrypick_request_type, @genotyping_request_type].map(&:id),
          asset_group_name: 'to avoid asset errors'
        )

      @genotype_pipeline = create(:pipeline, name: 'genotyping pipeline', request_types: [@genotyping_request_type])
      @cherrypick_pipeline = create(:pipeline, name: 'cherrypick pipeline', request_types: [@cherrypick_request_type])

      @request1 =
        create(
          :request_without_assets,
          asset: create(:sample_tube),
          target_asset: nil,
          submission: @submission,
          request_metadata_attributes: {},
          request_type: @cherrypick_request_type
        )
    end

    context 'with valid input' do
      before { @request2 = create(:request, submission: @submission, request_type: @genotyping_request_type) }

      it 'return the correct next request' do
        expect(@request1.next_requests).to eq([@request2])
      end
    end

    context 'where asset hasnt been created for second request' do
      before do
        @request2 = create(:request, asset: nil, submission: @submission, request_type: @genotyping_request_type)
      end

      it 'return the correct next request' do
        expect(@request1.next_requests).to eq([@request2])
      end
    end
  end

  # Next requests is used to find downstream requests
  # The current behaviour is explicitly linked to the order in which requests are created
  # so these tests use the submission builder. Please don't switch to building the requests
  # themselves via FactoryBot until the two behaviours are uncoupled
  describe '#next_requests' do
    let(:submission) { create(:submission, orders: [order1, order2], state: 'pending') }
    let(:order1) { create(:linear_submission, request_types: order1_request_types, request_options: request_options) }
    let(:order2) { create(:linear_submission, request_types: order2_request_types, request_options: request_options) }
    let(:order1_request1) do
      submission.requests.detect { |r| r.order == order1 && r.request_type_id == order1_request_types.first }
    end
    let(:order2_request1) do
      submission.requests.detect { |r| r.order == order2 && r.request_type_id == order2_request_types.first }
    end
    let(:request_options) { {} }

    before { submission.build_batch }

    context 'for a non-multiplexed_submission' do
      let(:order1_request_types) { create_list(:request_type, 3).map(&:id) }
      let(:order2_request_types) { order1_request_types }

      it 'returns a distinct request graph for each request' do
        expect(submission.requests.count).to eq(6)
        order1_request2 = order1_request1.next_requests
        expect(order1_request2.length).to eq(1)
        order1_request3 = order1_request2.first.next_requests
        expect(order1_request3.length).to eq(1)
        order2_request2 = order2_request1.next_requests
        expect(order2_request2.length).to eq(1)
        order2_request3 = order2_request2.first.next_requests
        expect(order2_request3.length).to eq(1)

        expect(order1_request1).not_to eq(order2_request1)
        expect(order1_request2).not_to eq(order2_request2)
        expect(order1_request2.first.request_type_id).to eq(order1_request_types[1])
        expect(order2_request2.first.request_type_id).to eq(order2_request_types[1])
        expect(order1_request3).not_to eq(order2_request3)
        expect(order1_request3.first.request_type_id).to eq(order1_request_types[2])
        expect(order2_request3.first.request_type_id).to eq(order2_request_types[2])
      end
    end

    context 'for a multiplexed_submission' do
      let(:order1_request_types) do
        [create(:request_type).id, create(:request_type, for_multiplexing: true).id, create(:request_type).id]
      end
      let(:order2_request_types) { order1_request_types }

      it 'returns a merging request graph for each request post multiplexing' do
        expect(submission.requests.count).to eq(5)
        order1_request2 = order1_request1.next_requests
        expect(order1_request2.length).to eq(1)
        order1_request3 = order1_request2.first.next_requests
        expect(order1_request3.length).to eq(1)
        order2_request2 = order2_request1.next_requests
        expect(order2_request2.length).to eq(1)
        order2_request3 = order2_request2.first.next_requests
        expect(order2_request3.length).to eq(1)

        expect(order1_request1).not_to eq(order2_request1)
        expect(order1_request2).not_to eq(order2_request2)
        expect(order1_request2.first.request_type_id).to eq(order1_request_types[1])
        expect(order2_request2.first.request_type_id).to eq(order2_request_types[1])
        expect(order1_request3).to eq(order2_request3)
        expect(order1_request3.first.request_type_id).to eq(order1_request_types[2])
        expect(order2_request3.first.request_type_id).to eq(order2_request_types[2])
      end
    end

    context 'for a multiplexed_submission with a multiplier' do
      let(:post_mx_request_type) { create(:request_type).id }
      let(:order1_request_types) do
        [create(:request_type).id, create(:request_type, for_multiplexing: true).id, post_mx_request_type]
      end
      let(:order2_request_types) { order1_request_types }

      let(:request_options) { { multiplier: { post_mx_request_type.to_s => 3 } } }

      it 'returns a merging request graph for each request post multiplexing' do
        expect(submission.requests.count).to eq(7)
        order1_request2 = order1_request1.next_requests
        expect(order1_request2.length).to eq(1)
        order1_request3 = order1_request2.first.next_requests
        expect(order1_request3.length).to eq(3)
        order2_request2 = order2_request1.next_requests
        expect(order2_request2.length).to eq(1)
        order2_request3 = order2_request2.first.next_requests
        expect(order2_request3.length).to eq(3)

        expect(order1_request1).not_to eq(order2_request1)
        expect(order1_request2).not_to eq(order2_request2)
        expect(order1_request2.first.request_type_id).to eq(order1_request_types[1])
        expect(order2_request2.first.request_type_id).to eq(order2_request_types[1])
        expect(order1_request3).to eq(order2_request3)
        expect(order1_request3.first.request_type_id).to eq(order1_request_types[2])
        expect(order2_request3.first.request_type_id).to eq(order2_request_types[2])
      end
    end

    context 'for a mixed-order multiplexed_submission' do
      let(:post_mx_request_type) { create(:request_type).id }
      let(:mx_request_type) { create(:request_type, for_multiplexing: true).id }
      let(:order1_request_types) { [create(:request_type).id, mx_request_type, post_mx_request_type] }
      let(:order2_request_types) { [create(:request_type).id, mx_request_type, post_mx_request_type] }

      it 'returns a merging request graph for each request post multiplexing' do
        expect(submission.requests.count).to eq(5)
        order1_request2 = order1_request1.next_requests
        expect(order1_request2.length).to eq(1)
        order1_request3 = order1_request2.first.next_requests
        expect(order1_request3.length).to eq(1)
        order2_request2 = order2_request1.next_requests
        expect(order2_request2.length).to eq(1)
        order2_request3 = order2_request2.first.next_requests
        expect(order2_request3.length).to eq(1)
        expect(order1_request1).not_to eq(order2_request1)
        expect(order1_request2).not_to eq(order2_request2)
        expect(order1_request2.length).to eq(1)
        expect(order1_request2.first.request_type_id).to eq(order1_request_types[1])
        expect(order2_request2.first.request_type_id).to eq(order2_request_types[1])
        expect(order1_request3).to eq(order2_request3)
        expect(order1_request3.length).to eq(1)
        expect(order1_request3.first.request_type_id).to eq(order1_request_types[2])
        expect(order2_request3.first.request_type_id).to eq(order2_request_types[2])
      end
    end
  end

  describe '#copy' do
    before do
      @request_type = create(:request_type)
      @request = create(:request, request_type: @request_type, study: study, state: 'failed')
      @new_request = @request.copy
    end

    it 'return same properties' do
      @request.reload
      @new_request.reload
      original_attributes =
        @request.request_metadata.attributes.merge('id' => nil, 'request_id' => nil, 'updated_at' => nil)
      copied_attributes =
        @new_request.request_metadata.attributes.merge('id' => nil, 'request_id' => nil, 'updated_at' => nil)
      expect(copied_attributes).to eq(original_attributes)
    end

    it 'remove target_asset' do
      expect(@new_request.target_asset_id).to be_nil
    end

    it 'be pending' do
      assert @new_request.pending?
    end
  end

  describe '#after_create' do
    context 'successful' do
      let(:study) { create(:study) }
      let(:request) { create(:request, study:) }

      it 'not have ActiveRecord errors' do
        expect(request.errors).to be_empty
      end

      it 'have request as valid' do
        expect(request).to be_valid
      end
    end
  end

  describe '#state' do
    before do
      @request = create(:request_suitable_for_starting, study:)
      @user = create(:admin)
      @user.grant_owner study
    end

    context 'when a new request is created' do
      it "return the default state 'pending'" do
        expect(@request.state).to eq('pending')
      end
    end

    context 'when started' do
      before { @request.start! }

      it "return 'Started'" do
        expect(@request.state).to eq 'started'
      end

      it 'not be pending' do
        expect(@request).not_to be_pending
      end

      it 'not be passed' do
        expect(@request).not_to be_passed
      end

      it 'not be failed' do
        expect(@request).not_to be_failed
      end

      it 'be started' do
        expect(@request).to be_started
      end

      context 'allow transition' do
        it 'to pass' do
          @request.pass!
        end

        it 'to fail' do
          @request.fail!
        end
      end
    end

    context 'when passed' do
      before do
        @request.state = 'started'
        @request.pass!
      end

      it "return status of 'passed'" do
        expect(@request.state).to eq('passed')
      end

      it 'not be pending' do
        expect(@request.pending?).to be(false)
      end

      it 'not be failed' do
        expect(@request.failed?).to be(false)
      end

      it 'not be started' do
        expect(@request.started?).to be(false)
      end

      it 'be passed' do
        assert @request.passed?
      end

      context 'do not allow the transition' do
        before { @request.state = 'passed' }

        it 'to started' do
          # At least we'll know when and where it's blowing up.
          expect { @request.start! }.to raise_error(AASM::InvalidTransition)
        end
      end
    end

    context 'when failed' do
      before do
        @request.state = 'started'
        @request.fail!
      end

      it "return status of 'failed'" do
        expect(@request.state).to eq('failed')
      end

      it 'not be pending' do
        expect(@request.pending?).to be(false)
      end

      it 'not be passed' do
        expect(@request.passed?).to be(false)
      end

      it 'not be started' do
        expect(@request.started?).to be(false)
      end

      it 'be failed' do
        assert @request.failed?
      end

      it 'not allow transition to passed' do
        expect { @request.pass! }.to raise_error(AASM::InvalidTransition)
        expect { @request.retrospective_pass! }.not_to raise_error
      end
    end
  end

  describe '#eventful_studies' do
    let(:asset) { create(:untagged_well) }
    let(:request) { create(:request, asset: asset, initial_study: study) }

    context 'with no study itself' do
      let(:study) { nil }

      it { expect(request.eventful_studies).to eq(asset.studies) }
    end

    context 'with a study itself' do
      let(:study) { create(:study) }

      it { expect(request.eventful_studies).to eq([study]) }
    end
  end

  describe '#open and #closed' do
    before do
      @open_states = %w[pending started]
      @closed_states = %w[passed failed cancelled]

      @all_states = @open_states + @closed_states

      @all_states.each { |state| create(:request, state:) }

      expect(described_class.count).to eq(@all_states.size)
    end

    context 'open requests' do
      it 'total right number' do
        expect(described_class.opened.count).to eq(@open_states.size)
      end
    end

    context 'closed requests' do
      it 'total right number' do
        expect(described_class.closed.count).to eq(@closed_states.size)
      end
    end
  end

  describe '#ready?' do
    before { @library_creation_request = create(:library_creation_request_for_testing_sequencing_requests) }

    it 'check any non-sequencing request is always ready' do
      expect(@library_creation_request.ready?).to be(true)
    end
  end

  describe '#customer_responsible' do
    before do
      @request = create(:library_creation_request)
      @request.state = 'started'
    end

    it 'update when request is started' do
      @request.request_metadata.update!(customer_accepts_responsibility: true)
      assert @request.request_metadata.customer_accepts_responsibility?
    end

    it 'not update once a request is failed' do
      @request.fail!
      expect do
        @request.request_metadata.update!(customer_accepts_responsibility: true)
      end.to raise_error ActiveRecord::RecordInvalid
    end
  end

  describe '::progress_statistics' do
    subject { described_class.progress_statistics }

    let(:request_type1) { create(:request_type) }
    let(:request_type2) { create(:request_type) }

    before do
      create_list(:request, 2, state: 'pending', request_type: request_type1)
      create_list(:request, 1, state: 'started', request_type: request_type1)
      create_list(:request, 3, state: 'passed', request_type: request_type1)
      create_list(:request, 1, state: 'failed', request_type: request_type1)
      create_list(:request, 2, state: 'pending', request_type: request_type2)
      create_list(:request, 1, state: 'started', request_type: request_type2)
      create_list(:request, 3, state: 'cancelled', request_type: request_type2)
      create_list(:request, 1, state: 'failed', request_type: request_type2)
    end

    it 'returns a summary' do
      expect(subject[request_type1]).to be_a Request::Statistics::Counter
      expect(subject[request_type1].total).to eq(7)
      expect(subject[request_type1].progress).to eq(50)
      expect(subject[request_type1].pending).to eq(2)
      expect(subject[request_type1].failed).to eq(1)
      expect(subject[request_type1].passed).to eq(3)
      expect(subject[request_type1].cancelled).to eq(0)
      expect(subject[request_type1].completed).to eq(4)
      expect(subject[request_type1].started).to eq(1)
      expect(subject[request_type2]).to be_a Request::Statistics::Counter
      expect(subject[request_type2].total).to eq(4)
      expect(subject[request_type2].progress).to eq(0)
      expect(subject[request_type2].pending).to eq(2)
      expect(subject[request_type2].failed).to eq(1)
      expect(subject[request_type2].passed).to eq(0)
      expect(subject[request_type2].cancelled).to eq(3)
      expect(subject[request_type2].completed).to eq(1)
      expect(subject[request_type2].started).to eq(1)
    end
  end

  describe '.get_all_comments' do
    let(:labware) { create(:labware) }
    let(:receptacle) { create(:receptacle, labware:) }
    let(:request) { create(:request, asset: receptacle) }

    before do
      create(:comment, commentable: labware, description: 'comment on labware')
      create(:comment, commentable: receptacle, description: 'comment on receptacle')
      create(:comment, commentable: request, description: 'first comment on request')
      create(:comment, commentable: request, description: 'second comment on request')
    end

    it 'returns all of the comments including associated labware, receptacle and request itself' do
      expect(described_class.get_all_comments(request)).to eq(4)
    end
  end
end
