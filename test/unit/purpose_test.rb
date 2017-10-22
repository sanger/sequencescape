require 'test_helper'

class PurposeTest < ActiveSupport::TestCase
  context 'A purpose' do
    setup do
      @purpose = create :purpose
    end

    context 'with an unrelated parent' do
      setup do
        @other_purpose = create :purpose
      end

      should 'return a generic transfer request' do
        assert_equal RequestType.transfer, @purpose.transfer_request_type_from(@other_purpose)
      end
    end

    context 'with a defined parent' do
      setup do
        @other_purpose = create :purpose
        @custom_request = create :request_type
        create :purpose_relationship, parent: @other_purpose, child: @purpose, transfer_request_type: @custom_request
      end

      should 'return the specific transfer request type' do
        assert_equal @custom_request, @purpose.transfer_request_type_from(@other_purpose)
      end
    end

    context 'with a stock parent' do
      setup do
        @other_purpose = create :stock_purpose
      end

      should 'return a initial transfer request' do
        assert_equal RequestType.initial_transfer, @purpose.transfer_request_type_from(@other_purpose)
      end
    end
  end
end
