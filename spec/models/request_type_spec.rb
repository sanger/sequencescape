require 'rails_helper'

describe RequestType do
  context RequestType do
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
        expect { @deprecated_request_type.create! }.to raise_error RequestType::DeprecatedError
      end
    end

    context 'with billing product catalogue' do
      it 'should assign the right product to request' do
        request_type = RequestType.find_by(key: :illumina_c_miseq_sequencing)
        billing_product_catalogue = create :miseq_paired_end_product_catalogue
        billing_product = (create :billing_product,
                                  name: 'product_with_read_length_250',
                                  identifier: 250,
                                  billing_product_catalogue: billing_product_catalogue)
        request_type.billing_product_catalogue = billing_product_catalogue
        request = request_type.create!(
          request_metadata: SequencingRequest::Metadata.new(
            read_length: 250,
            fragment_size_required_to: 150,
            fragment_size_required_from: 150
          )
        )
        expect(request.billing_product).to eq billing_product
      end
    end
  end
end
