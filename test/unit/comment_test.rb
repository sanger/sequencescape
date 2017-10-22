# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

require 'test_helper'

class CommentTest < ActiveSupport::TestCase
  context 'A comment' do
    should belong_to :commentable
    should belong_to :user
    should have_many :comments
  end

  context 'while adding comments to requests' do
    setup do
      @study = create :study
      @project = create :project

      @asset = create :empty_sample_tube
      @asset.aliquots.create!(sample: create(:sample, studies: [@study]))

      @asset2 = create :empty_sample_tube
      @asset2.aliquots.create!(sample: create(:sample, studies: [@study]))

      @order1 = create :order_with_submission, study: @study, assets: [@asset], project: @project
      @order2 = create :order,  study: @study, assets: [@asset], project: @project
      @order3 = create :order,  study: @study, assets: [@asset2], project: @project
      @order4 = create :order_with_submission,  study: @study, assets: [@asset2], project: @project

      @submission = @order1.submission
      @submission.orders.push(@order2)
      @submission.orders.push(@order3)

      @submission2 = @order4.submission

      @sequencing_request = create :request_with_sequencing_request_type, submission: @submission
      @request = create :request, order: @order1, asset: @asset, submission: @submission
      @request2 = create :request, order: @order2, submission: @submission

      @request3 = create :request, order: @order4, submission: @order4.submission
      @sequencing_request2 = create :request_with_sequencing_request_type, submission: @order4.submission
    end
    context 'from an order' do
      setup do
        @order1.add_comment('My comment to order 1', @user)
        # From a different order
        @order2.add_comment('My comment to order 2', @user)
        # Order without own requests
        @order3.add_comment('My comment to order 3', @user)
        # Order from a different submission
        @order4.add_comment('My comment to order 4', @user)
      end
      should 'add comments just to the requests that relates with the order' do
        assert_equal 1, @request.comments.length
        assert_equal 1, @request2.comments.length
        assert_equal 1, @request3.comments.length
      end
      should 'always add comments to the sequencing requests of the submission' do
        assert_equal 3, @sequencing_request.comments.length
        assert_equal 1, @sequencing_request2.comments.length
      end
      should 'include all the comments in the submission requests comment list' do
        assert_equal 5, @submission.requests.map(&:comments).flatten.length
        assert_equal 2, @order4.submission.requests.map(&:comments).flatten.length
      end
    end
    context 'from a submission' do
      setup do
        @submission.add_comment('My comment from submission 1', @user)
        @submission2.add_comment('My comment from submission 2', @user)
      end
      should 'include that comment in all the requests of the submission' do
        @submission.requests.all? { |r| r.comments.length == 1 }
        @submission2.requests.all? { |r| r.comments.length == 1 }
      end
    end
  end
end
