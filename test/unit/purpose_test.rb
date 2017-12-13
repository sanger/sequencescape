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
        assert_equal TransferRequest::Standard, @purpose.transfer_request_class_from(@other_purpose)
      end
    end

    context 'with a defined parent' do
      setup do
        @other_purpose = create :purpose
        create :purpose_relationship, parent: @other_purpose, child: @purpose, transfer_request_class_name: :initial_downstream
      end

      should 'return the specific transfer request type' do
        assert_equal TransferRequest::InitialDownstream, @purpose.transfer_request_class_from(@other_purpose)
      end
    end

    context 'with a stock parent' do
      setup do
        @other_purpose = create :stock_purpose
      end

      should 'return a initial transfer request' do
        assert_equal TransferRequest::Initial, @purpose.transfer_request_class_from(@other_purpose)
      end
    end
  end
end
