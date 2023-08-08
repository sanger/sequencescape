# frozen_string_literal: true

require 'rails_helper'
require 'record_loader/product_catalogue_loader'

# This file was initially generated via `rails g record_loader`
RSpec.describe RecordLoader::ProductCatalogueLoader, loader: true, type: :model do
  subject(:record_loader) { described_class.new(directory: test_directory, files: selected_files) }

  # Tests use a separate directory to avoid coupling your specs to the data
  let(:test_directory) { Rails.root.join('spec/data/record_loader/product_catalogues') }

  context 'with two_entry_example selected' do
    let(:selected_files) { 'two_catalogues' }

    it 'creates two records' do
      expect { record_loader.create! }.to change(ProductCatalogue, :count).by(2)
    end

    # It is important that multiple runs of a RecordLoader do not create additional
    # copies of existing records.
    it 'is idempotent' do
      record_loader.create!
      expect { record_loader.create! }.not_to change(ProductCatalogue, :count)
    end

    it 'sets attributes on the created records' do
      record_loader.create!

      rec1 = ProductCatalogue.find_by(name: 'catalogue1')
      rec2 = ProductCatalogue.find_by(name: 'catalogue2')

      expect(rec1).to have_attributes(selection_behaviour: 'SingleProduct')

      expect(rec2).to have_attributes(selection_behaviour: 'SingleProduct')
    end
  end
end
