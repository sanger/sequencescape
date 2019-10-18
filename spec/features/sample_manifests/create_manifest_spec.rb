# frozen_string_literal: true

require 'rails_helper'

describe 'SampleManifest controller', sample_manifest: true do
  def load_manifest_spec
    SampleManifestExcel.configure do |config|
      config.folder = File.join('spec', 'data', 'sample_manifest_excel')
      config.load!
    end
  end

  let(:user) { create :user }
  let!(:printer) { create :barcode_printer }
  let!(:supplier) { create :supplier }
  let!(:study) { create :study }
  let(:barcode) { 1000 }
  let(:created_plate) do
    Plate.with_barcode(SBCF::SangerBarcode.new(prefix: 'DN', number: barcode).human_barcode).first
  end

  shared_examples 'a plate manifest' do
    it 'creating manifests' do
      click_link('Create manifest for plates')
      expect(PlateBarcode).to receive(:create).and_return(build(:plate_barcode, barcode: barcode))
      select(study.name, from: 'Study')
      select(supplier.name, from: 'Supplier')
      within('#sample_manifest_template') do
        expect(page).to have_selector('option', count: 5)
        expect(page).not_to have_selector('option', text: 'Default Tube')
      end
      select('Default Plate', from: 'Template')
      select(printer.name, from: 'Barcode printer')
      select(selected_purpose.name, from: 'purpose') if selected_purpose
      click_button('Create manifest and print labels')
      expect(page).to have_text('Upload a sample manifest')
      expect(created_plate.purpose).to eq(created_purpose)
      click_on 'Download Blank Manifest'
      expect(page.driver.response.headers['Content-Type']).to(
        eq('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
      )
    end
  end

  before do
    login_user user
    load_manifest_spec
    visit(study_path(study))
    click_link('Sample Manifests')
  end

  context 'with no default' do
    let(:selected_purpose) { false }
    let(:created_purpose) { PlatePurpose.stock_plate_purpose }

    it_behaves_like 'a plate manifest'
  end

  context 'with a selected purpose' do
    let(:selected_purpose) { created_purpose }
    let!(:created_purpose) { create :plate_purpose, stock_plate: true }

    it_behaves_like 'a plate manifest'
  end

  context 'without a type specified' do
    let!(:created_purpose) { create :plate_purpose, stock_plate: true }

    it 'indicate the purpose field is used for plates only' do
      visit(new_sample_manifest_path)
      within('#sample_manifest_template') do
        expect(page).to have_selector('option', count: 16)
      end
      select(created_purpose.name, from: 'purpose')
      expect(page).to have_text('Used for plate manifests only')
    end
  end
end
