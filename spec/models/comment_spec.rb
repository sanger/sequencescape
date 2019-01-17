# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Comment, type: :model do
  context 'A comment has relationships' do
    it 'should belong to commentable' do
      belong_to :commentable
    end

    it 'should belong to a user' do
      belong_to :user
    end

    it 'can have many comments' do
      should have_many :comments
    end
  end

  context 'while adding comments to requests' do
    let(:user) { create :user }
    let(:study) { create :study }
    let(:project) { create :project }

    let(:asset) { create :empty_sample_tube }

    let(:asset2) { create :empty_sample_tube }

    let(:order1) { create :order_with_submission, study: study, assets: [asset], project: project }
    let(:order2) { create :order,  study: study, assets: [asset], project: project }
    let(:order3) { create :order,  study: study, assets: [asset2], project: project }
    let(:order4) { create :order_with_submission,  study: study, assets: [asset2], project: project }

    let(:submission) { order1.submission }
    let(:submission2) { order4.submission }

    let(:sequencing_request) { create :request_with_sequencing_request_type, submission: submission }
    let(:request) { create :request, order: order1, asset: asset, submission: submission }
    let(:request2) { create :request, order: order2, submission: submission }

    let(:request3) { create :request, order: order4, submission: order4.submission }
    let(:sequencing_request2) { create :request_with_sequencing_request_type, submission: order4.submission }

    before do
      sequencing_request
      request
      request2
      sequencing_request2
      request3
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
        assert_equal 1, request.comments.length
        assert_equal 1, request2.comments.length
        assert_equal 1, request3.comments.length
      end

      it 'always adds comments to the sequencing requests of the submission' do
        assert_equal 3, sequencing_request.comments.length
        assert_equal 1, sequencing_request2.comments.length
      end

      it 'includes all the comments in the submission requests comment list' do
        assert_equal 5, submission.requests.map(&:comments).flatten.length
        assert_equal 2, order4.submission.requests.map(&:comments).flatten.length
      end
    end

    context 'from a submission' do
      setup do
        submission.add_comment('My comment from submission 1', user)
        submission2.add_comment('My comment from submission 2', user)
      end

      it 'includes that comment in all the requests of the submission' do
        submission.requests.all? { |r| r.comments.length == 1 }
        submission2.requests.all? { |r| r.comments.length == 1 }
      end
    end

    context 'adding to a plate' do
      let(:plate) { create :plate, well_count: 1 }
      let(:submission) { create :submission }
      let(:request) { create :request, asset: plate.wells.first, submission: submission }

      before do
        request
      end

      it 'also adds to the request' do
        create :comment, commentable: plate, description: 'Hello'
        assert_equal request.reload.comments.first.description, 'Hello'
      end
    end
  end
end
