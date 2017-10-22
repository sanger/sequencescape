# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

require 'test_helper'

class RequestTypeTest < ActiveSupport::TestCase
  context RequestType do
    should have_many :requests
    #    should_belong_to :workflow, :class_name => "Submission::Workflow"
    should validate_presence_of :order
    should validate_presence_of :request_purpose
    should validate_numericality_of :order

    context '#for_multiplexing?' do
      context 'when it is for multiplexing' do
        setup do
          @request_type = create :multiplexed_library_creation_request_type
        end

        should 'return true' do
          assert @request_type.for_multiplexing?
        end
      end

      context 'when it is not for multiplexing' do
        setup do
          @request_type = create :library_creation_request_type
        end

        should 'return false' do
          assert !@request_type.for_multiplexing?
        end
      end
    end

    context 'when not deprecated,' do
      setup do
        @non_deprecated_request_type = create(:request_type)
      end

      should 'create requests' do
        @non_deprecated_request_type.create!
      end
    end

    context 'with a purpose' do
      setup do
        @rp = create(:request_purpose)
        @nrequest_type = create(:request_type, request_purpose: @rp)
      end

      should 'set purpose on request' do
        request = @nrequest_type.create!
        assert_equal @rp, request.request_purpose
      end
    end

    context 'when deprecated,' do
      setup do
        @deprecated_request_type = create(:request_type, deprecated: true)
      end

      should 'not create deprecated requests' do
        assert_raise RequestType::DeprecatedError do
          @deprecated_request_type.create!
        end
      end
    end
  end
end
