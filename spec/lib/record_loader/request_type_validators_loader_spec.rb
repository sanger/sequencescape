# frozen_string_literal: true

require 'rails_helper'
require 'record_loader/request_type_validators_loader'

RSpec.describe RecordLoader::RequestTypeValidatorsLoader, :loader, type: :model do
  def a_new_record_loader(files = selected_files)
    described_class.new(directory: test_directory, files: files)
  end

  subject(:record_loader) { a_new_record_loader }

  # Tests use a separate directory to avoid coupling your specs to the data
  let(:test_directory) { Rails.root.join('spec/data/record_loader/request_type_validators') }
  let(:example_request_type_key) { 'example_request_type_key' }
  let(:selected_files) { 'two_request_type_validators_example.yml' }

  # Create request type to link the validators to
  before do
    create(:request_type, key: example_request_type_key)
  end

  context 'with example yml file' do
    it 'creates two records' do
      expect { record_loader.create! }.to change(RequestType::Validator, :count).by(2)
    end
  end

  context 'when a request type validator already exists' do
    before do
      create(:request_type_validator,
             request_type: RequestType.find_by(key: example_request_type_key),
             request_option: 'flowcell_requested_example',
             valid_options: 'some options')
    end

    it 'does not duplicate existing request types' do
      expect { record_loader.create! }.to change(RequestType::Validator, :count).by(1)
    end

    it 'updates the existing request type validator to new values' do
      expect { record_loader.create! }.to change {
        RequestType::Validator.find_by(
          request_type_id: RequestType.find_by(key: example_request_type_key).id,
          request_option: 'flowcell_requested_example'
        ).valid_options
      }.from('some options').to(
        be_a(RequestType::Validator::FlowcellTypeValidator)
      )
    end
  end

  context 'when it has been created' do
    before { record_loader.create! }

    # It is important that multiple runs of a RecordLoader do not create additional
    # copies of existing records.
    it 'is idempotent' do
      # create a new instance to avoid caching issues
      record_loader = a_new_record_loader(selected_files)
      expect { record_loader.create! }.not_to change(RequestType::Validator, :count)
    end

    it 'sets attributes on the created records' do
      expect(RequestType::Validator.last).to have_attributes(
        request_type_id: RequestType.find_by(key: example_request_type_key).id,
        request_option: 'read_length_example',
        valid_options: [50, 100, 150],
        key: 'ReadLengthExample'
      )
    end
  end
end
