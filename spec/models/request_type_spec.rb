# frozen_string_literal: true

require 'rails_helper'

describe RequestType do
  context described_class do
    describe '#for_multiplexing?' do
      context 'when it is for multiplexing' do
        let(:request_type) { create(:multiplexed_library_creation_request_type) }

        it 'return true' do
          expect(request_type).to be_for_multiplexing
        end
      end

      context 'when it is not for multiplexing' do
        let(:request_type) { create(:library_creation_request_type) }

        it 'return false' do
          expect(request_type).not_to be_for_multiplexing
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
      before do
        @rp = :internal
        @nrequest_type = create(:request_type, request_purpose: @rp)
      end

      it 'set purpose on request' do
        request = @nrequest_type.create!
        expect(request.request_purpose).to eq('internal')
      end
    end

    context 'when deprecated,' do
      before { @deprecated_request_type = create(:request_type, deprecated: true) }

      it 'not create deprecated requests' do
        expect { @deprecated_request_type.create! }.to raise_error RequestType::DeprecatedError
      end
    end
  end
end
