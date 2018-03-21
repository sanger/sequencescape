require 'rails_helper'

describe RequestType do
  context RequestType do
    context '#for_multiplexing?' do
      context 'when it is for multiplexing' do
        let(:request_type) { create :multiplexed_library_creation_request_type }

        it 'return true' do
          assert request_type.for_multiplexing?
        end
      end

      context 'when it is not for multiplexing' do
        let(:request_type) { create :library_creation_request_type }

        it 'return false' do
          refute request_type.for_multiplexing?
        end
      end
    end

    context 'when not deprecated,' do
      let(:request_type) { create(:request_type) }

      it 'create requests' do
        request_type.create!
      end
    end

    context 'with a purpose' do
      setup do
        @rp = :internal
        @nrequest_type = create(:request_type, request_purpose: @rp)
      end

      it 'set purpose on request' do
        request = @nrequest_type.create!
        assert_equal 'internal', request.request_purpose
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
      let(:request_type) { create :miseq_sequencing_request_type, billing_product_catalogue: billing_product_catalogue }
      let(:billing_product_catalogue) { create :miseq_paired_end_product_catalogue }
      let!(:billing_product) do
        create :billing_product,
               name: 'product_with_read_length_250',
               identifier: 250,
               billing_product_catalogue: billing_product_catalogue
      end

      it 'should assign the right product to request' do
        request = request_type.create!(
          request_metadata_attributes: {
            read_length: 250,
            fragment_size_required_to: 150,
            fragment_size_required_from: 150
          }
        )
        expect(request.billing_product).to eq billing_product
      end
    end
  end
end
