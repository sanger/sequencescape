# frozen_string_literal: true

require 'rails_helper'

describe 'SampleManifest controller', :sample_manifest do
  def load_manifest_spec
    SampleManifestExcel.configure do |config|
      config.folder = File.join('spec', 'data', 'sample_manifest_excel')
      config.load!
    end
  end

  let(:user) { create(:user) }
  let!(:printer) { create(:barcode_printer) }
  let!(:supplier) { create(:supplier) }
  let!(:study) { create(:study) }
  let(:plate_barcode) { build(:plate_barcode) }
  let(:created_plate) { Plate.with_barcode(plate_barcode.barcode).first }

  shared_examples 'a plate manifest' do
    it 'creating manifests' do
      click_link('Create manifest for plates')
      expect(PlateBarcode).to receive(:create_barcode).and_return(plate_barcode)
      select(study.name, from: 'Study')
      select(supplier.name, from: 'Supplier')
      within('#sample_manifest_template') do
        expect(page).to have_css('option', count: 10)
        expect(page).to have_no_css('option', text: 'Default Tube')
      end
      select('Default Plate', from: 'Template')
      select(printer.name, from: 'Barcode printer')
      select(selected_purpose.name, from: 'Purpose') if selected_purpose
      click_button('Create manifest and print labels')
      expect(page).to have_text('Upload a Sample Manifest')
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
    let!(:created_purpose) { create(:plate_purpose, stock_plate: true) }

    it_behaves_like 'a plate manifest'
  end

  context 'without a type specified' do
    let!(:created_purpose) { create(:plate_purpose, stock_plate: true) }
    let(:flag) { :y26_147_2_enable_compound_sample_tube_manifests }
    let(:kinnex_template) { 'Kinnex Compound Sample Tube' }

    it 'indicate the purpose field is used for plates only' do
      visit(new_sample_manifest_path)
      within('#sample_manifest_template') do
        expect(page).to have_css('option', count: 26)
      end
      select(created_purpose.name, from: 'Purpose')
      expect(page).to have_text('Used for plate manifests only')
    end

    it 'hides compound sample tube templates while the feature flag is off' do
      Flipper.disable(flag)
      visit(new_sample_manifest_path)
      template_field = find_field('Template')
      expect(template_field).to have_no_css('option', text: kinnex_template)
    end

    it 'lists compound sample tube templates when the feature flag is on' do
      Flipper.enable(flag)
      visit(new_sample_manifest_path)
      expect(page).to have_select('Template', with_options: [kinnex_template])
    end
  end

  context 'with a tube rack manifest' do
    let!(:selected_purpose) { create(:sample_tube_purpose, name: 'Standard sample') }
    let!(:selected_tube_rack_purpose) { create(:tube_rack_purpose, name: 'TR Stock 96') }

    it 'creating manifests' do
      click_link('Create manifest for tube racks')
      select(study.name, from: 'Study')
      select(supplier.name, from: 'Supplier')
      within('#sample_manifest_template') do
        expect(page).to have_css('option', count: 2)
        expect(page).to have_css('option', text: 'Default Tube Rack')
      end
      select('Default Tube Rack', from: 'Template')
      expect(page).to have_no_text('Barcodes')
      expect(page).to have_text('Tube racks required')
      select(selected_purpose.name, from: 'Tube purpose') if selected_purpose
      expect(page).to have_text('Tube rack purpose')
      within('#sample_manifest_tube_rack_purpose_input') do
        expect(page).to have_css('option', count: 2)
        expect(page).to have_css('option', text: selected_tube_rack_purpose.name)
      end
      select(selected_tube_rack_purpose.name, from: 'Tube rack purpose') if selected_tube_rack_purpose
      click_button('Create manifest')
      expect(page).to have_text('Upload a Sample Manifest')
      click_on 'Download Blank Manifest'
      expect(page.driver.response.headers['Content-Type']).to(
        eq('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
      )
    end
  end
end
