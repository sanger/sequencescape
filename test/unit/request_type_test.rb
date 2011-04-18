require "test_helper"

class RequestTypeTest < ActiveSupport::TestCase
  context RequestType do
    should_have_many :requests
#    should_belong_to :workflow, :class_name => "Submission::Workflow"
    should_validate_presence_of :order
    should_validate_numericality_of :order

    context '#for_multiplexing?' do
      context 'when it is for multiplexing' do
        setup do
          @request_type = Factory :multiplexed_library_creation_request_type
        end

        should 'return true' do
          assert @request_type.for_multiplexing?
        end
      end

      context 'when it is not for multiplexing' do
        setup do
          @request_type = Factory :library_creation_request_type
        end

        should 'return false' do
          assert !@request_type.for_multiplexing?
        end
      end
    end
  end
end
