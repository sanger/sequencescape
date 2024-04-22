# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Comment do
  context 'A comment has relationships' do
    it 'belongs to commentable' do
      expect(subject).to belong_to(:commentable).required
    end

    it 'belongs to a user' do
      expect(subject).to belong_to :user
    end

    it 'can have many comments' do
      expect(subject).to have_many :comments
    end
  end

  describe '#counts_for_requests' do
    let(:request) { create(:sequencing_request, asset: tube) }
    let(:tube) { create(:multiplexed_library_tube) }

    before do
      create(:comment, commentable: tube, description: 'An excellent tube')
      create(:comment, commentable: tube.receptacle, description: 'A good receptacle')
      create(:comment, commentable: request, description: 'A reasonable request')
    end

    it 'counts comments on requests, their assets and receptacles' do
      expect(described_class.counts_for_requests([request])).to eq({ request.id => 3 })
    end
  end

  context 'while adding comments to requests' do
    let(:user) { create(:user) }
    let(:study) { create(:study) }
    let(:project) { create(:project) }

    let(:asset) { create(:empty_sample_tube) }

    let(:asset2) { create(:empty_sample_tube) }

    let(:order1) { create(:order_with_submission, study:, assets: [asset], project:) }
    let(:order2) { create(:order, study:, assets: [asset], project:) }
    let(:order3) { create(:order, study:, assets: [asset2], project:) }
    let(:order4) { create(:order_with_submission, study:, assets: [asset2], project:) }

    let(:submission) { order1.submission }
    let(:submission2) { order4.submission }

    let!(:sequencing_request) { create(:request_with_sequencing_request_type, submission:) }
    let!(:request) { create(:request, order: order1, asset:, submission:) }
    let!(:request2) { create(:request, order: order2, submission:) }

    let!(:request3) { create(:request, order: order4, submission: order4.submission) }
    let!(:sequencing_request2) { create(:request_with_sequencing_request_type, submission: order4.submission) }

    before do
      asset.aliquots.create!(sample: create(:sample, studies: [study]))
      asset2.aliquots.create!(sample: create(:sample, studies: [study]))
      submission.orders.push(order2)
      submission.orders.push(order3)
    end

    context 'from an order' do
      before do
        order1.add_comment('My comment to order 1', user)

        # From a different order
        order2.add_comment('My comment to order 2', user)

        # Order without own requests
        order3.add_comment('My comment to order 3', user)

        # Order from a different submission
        order4.add_comment('My comment to order 4', user)
      end

      it 'adds comments just to the requests that relates with the order' do
        expect(request.comments.length).to eq(1)
        expect(request2.comments.length).to eq(1)
        expect(request3.comments.length).to eq(1)
      end

      it 'always adds comments to the sequencing requests of the submission' do
        expect(sequencing_request.comments.length).to eq(3)
        expect(sequencing_request2.comments.length).to eq(1)
      end

      it 'includes all the comments in the submission requests comment list' do
        expect(submission.requests.map(&:comments).flatten.length).to eq(5)
        expect(order4.submission.requests.map(&:comments).flatten.length).to eq(2)
      end
    end

    context 'from a submission' do
      before do
        submission.add_comment('My comment from submission 1', user)
        submission2.add_comment('My comment from submission 2', user, 'Test')
      end

      it 'includes that comment in all the requests of the submission' do
        expect(submission.requests.count).to eq(3)
        expect(submission2.requests.count).to eq(2)
        submission.requests.all? { |r| expect(r.comments.length).to eq(1) }
        submission2.requests.all? { |r| expect(r.comments.length).to eq(1) }
      end

      it 'sets the title on request comments' do
        submission2.requests.all? { |r| expect(r.comments.first.title).to eq('Test') }
      end
    end

    context 'adding to a plate' do
      let(:plate) { create(:plate, well_count: 1) }
      let(:submission) { create(:submission) }
      let!(:request) { create(:request, asset: plate.wells.first, submission:) }

      it 'also adds to the request' do
        create(:comment, commentable: plate, description: 'Hello')
        expect(request.reload.comments.first.description).to eq('Hello')
      end

      it 'propagates titles' do
        create(:comment, commentable: plate, description: 'Hello', title: 'Test')
        expect(request.reload.comments.first.title).to eq('Test')
      end
    end
  end
end
