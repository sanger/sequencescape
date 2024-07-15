# frozen_string_literal: true

require 'rails_helper'

describe RequestType::Validator::LibraryTypeValidator do
  let(:library_type) { create :library_type, name: 'MyLibraryType' }
  let(:request_type) { create :library_creation_request_type, :with_library_types, library_type: library_type }
  let(:validator) { described_class.new(request_type.id) }

  context 'when initialising' do
    it 'keeps an association with the request type' do
      expect(validator.request_type_id).to eq(request_type.id)
    end
  end

  context 'when validating library type' do
    context 'when exists and case matches' do
      it 'returns true' do
        expect(validator.include?('MyLibraryType')).to be(true)
      end
    end

    context 'when exists and case does not match' do
      it 'returns false' do
        expect(validator.include?('mylibrarytype')).to be(false)
      end
    end

    context 'when is not recognised' do
      it 'returns false' do
        expect(validator.include?('unknown')).to be(false)
      end
    end
  end

  context 'when using default' do
    let(:request_type) { create :request_type }
    let(:library_type2) { create :library_type, name: 'MyDefaultLibraryType' }

    context 'when a default library type is set' do
      before do
        request_type.library_types_request_types << create(
          :library_types_request_type,
          library_type: library_type,
          request_type: request_type,
          is_default: false
        )
        request_type.library_types_request_types << create(
          :library_types_request_type,
          library_type: library_type2,
          request_type: request_type,
          is_default: true
        )
      end

      it 'returns the name' do
        expect(validator.default).to eq('MyDefaultLibraryType')
      end
    end

    context 'when a default library type is not set' do
      before do
        request_type.library_types_request_types << create(
          :library_types_request_type,
          library_type: library_type,
          request_type: request_type,
          is_default: false
        )
        request_type.library_types_request_types << create(
          :library_types_request_type,
          library_type: library_type2,
          request_type: request_type,
          is_default: false
        )
      end

      it 'returns nil' do
        expect(validator.default).to be_nil
      end
    end
  end

  context 'when using to_a' do
    it 'returns expected array' do
      expected_array = ['MyLibraryType']
      expect(validator.to_a).to eq(expected_array)
    end
  end
end
