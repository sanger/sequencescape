# frozen_string_literal: true

require 'rails_helper'
require 'record_loader/request_type_loader'

# This file was initially generated via `rails g record_loader`
RSpec.describe RecordLoader::RequestTypeLoader, type: :model, loader: true do
  def a_new_record_loader
    described_class.new(directory: test_directory, files: selected_files)
  end

  subject(:record_loader) { a_new_record_loader }

  # Tests use a separate directory to avoid coupling your specs to the data
  let(:test_directory) { Rails.root.join('spec/data/record_loader/request_types') }

  context 'with request_types_basic selected' do
    let(:selected_files) { 'request_types_basic' }

    it 'creates two records' do
      expect { record_loader.create! }.to change(RequestType, :count).by(2)
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
    end
  end
end
