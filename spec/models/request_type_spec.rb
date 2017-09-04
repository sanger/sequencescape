require 'rails_helper'
require 'shoulda'

describe RequestType do
  context RequestType do

    it 'has write associations and validations' do
      should have_many :requests
      should belong_to :billing_product_catalogue
      #    should_belong_to :workflow, :class_name => "Submission::Workflow"
      should validate_presence_of :order
      should validate_presence_of :request_purpose
      should validate_numericality_of :order
    end

    context '#for_multiplexing?' do
      context 'when it is for multiplexing' do
        setup do
          @request_type = create :multiplexed_library_creation_request_type
        end

        it 'return true' do
          assert @request_type.for_multiplexing?
        end
      end

      context 'when it is not for multiplexing' do
        setup do
          @request_type = create :library_creation_request_type
        end

        it 'return false' do
          assert !@request_type.for_multiplexing?
        end
      end
    end

    context 'when not deprecated,' do
      setup do
        @non_deprecated_request_type = create(:request_type)
      end

      it 'create requests' do
        @non_deprecated_request_type.create!
      end
    end

    context 'with a purpose' do
      setup do
        @rp = create(:request_purpose)
        @nrequest_type = create(:request_type, request_purpose: @rp)
      end

      it 'set purpose on request' do
        request = @nrequest_type.create!
        assert_equal @rp, request.request_purpose
      end
    end

    context 'when deprecated,' do
      setup do
        @deprecated_request_type = create(:request_type, deprecated: true)
      end

      it 'not create deprecated requests' do
        expect{ @deprecated_request_type.create! }.to raise_error RequestType::DeprecatedError
      end
    end
  end
end