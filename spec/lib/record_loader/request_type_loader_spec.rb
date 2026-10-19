# frozen_string_literal: true

require 'rails_helper'
require 'record_loader/request_type_loader'

# This file was initially generated via `rails g record_loader`
RSpec.describe RecordLoader::RequestTypeLoader, :loader, type: :model do
  def a_new_record_loader(files = selected_files)
    described_class.new(directory: test_directory, files: files)
  end

  subject(:record_loader) { a_new_record_loader }

  before do
    create(:plate_purpose, name: 'Example purpose')
    create(:library_type, name: 'Standard')
  end

  # Tests use a separate directory to avoid coupling your specs to the data
  let(:test_directory) { Rails.root.join('spec/data/record_loader/request_types') }

  context 'with request_types_basic selected' do
    let(:selected_files) { 'request_types_basic' }

    it 'creates two records' do
      expect { record_loader.create! }.to change(RequestType, :count).by(2)
    end

    it 'does not duplicate existing library types' do
      expect { record_loader.create! }.to change(LibraryType, :count).by(1)
    end

    context 'when it has been created' do
      before { record_loader.create! }

      # It is important that multiple runs of a RecordLoader do not create additional
      # copies of existing records.
      it 'is idempotent' do
        expect { record_loader.create! }.not_to change(RequestType, :count)
      end

      # If I split this out into independent tests, than RSpec/AggregateFailures shouts at me,
      # and the overall readability feels reduced. So overruling RuboCop here.
      it 'sets attributes on the created records' do
        expect(RequestType.last).to have_attributes(
          name: 'Example type 2',
          asset_type: 'Well',
          order: 2,
          target_asset_type: 'Well',
          request_class_name: 'CherrypickForPulldownRequest',
          initial_state: 'pending'
        )
      end

      it 'sets acceptable purposes' do
        expect(RequestType.last.acceptable_purposes).to contain_exactly(have_attributes(name: 'Example purpose'))
      end

      it 'sets library types' do
        expect(RequestType.last.library_types).to contain_exactly(
          have_attributes(name: 'Standard'),
          have_attributes(name: 'Chromium single cell CNV')
        )
      end
    end
  end

  context 'when run on an updated file' do
    let(:selected_files) { 'request_types_updated' }

    before do
      create(:plate_purpose, name: 'Example purpose 2')
      a_new_record_loader('request_types_basic').create!
      record_loader.create!
    end

    # NOTE: Not removing library types or purposes here is intentional, as they
    # are occasionally added via the console, and removing them on deployment could
    # cause confusion.
    it 'adds new library types to the list' do
      expect(RequestType.last.library_types).to contain_exactly(
        have_attributes(name: 'Standard'),
        have_attributes(name: 'Chromium single cell CNV'),
        have_attributes(name: 'Added library type')
      )
    end

    it 'adds new purposes to the list' do
      expect(RequestType.last.acceptable_purposes).to contain_exactly(
        have_attributes(name: 'Example purpose'),
        have_attributes(name: 'Example purpose 2')
      )
    end
  end

  context 'when the request type exists but we are updating request_class_name' do
    let(:selected_files) { 'request_types_updated_class_name' }

    before do
      create(:plate_purpose, name: 'Example purpose 2')
      a_new_record_loader('request_types_basic').create!
      record_loader.create!
    end

    it 'updates the request class name of the last record' do
      expect(RequestType.last.request_class_name).to eq('SequencingRequest')
    end

    it 'does not change the request class name of the first record' do
      expect(RequestType.first.request_class_name).to eq('SequencingRequest')
    end
  end
end
