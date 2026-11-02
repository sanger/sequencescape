# frozen_string_literal: true

require 'rails_helper'

# Migrated from features/sample_manifest/sample_manifest.feature
describe 'Sample manifest', :sample_manifest do
  let(:user) { create(:user) }
  let!(:supplier) { create(:supplier) }
  let!(:study) { create(:study) }
  let!(:printer) do
    create(:barcode_printer,
           barcode_printer_type: BarcodePrinterType1DTube.first)
  end

  # Fills in the form for a Default Tube manifest of the given number of
  # tubes, up to the options for printing
  def fill_in_tube_manifest(tubes)
    click_link('Create manifest for tubes')
    select(study.name, from: 'Study')
    select('Default Tube', from: 'Template')
    select('Standard sample', from: 'Purpose')
    select(supplier.name, from: 'Supplier')
    select(printer.name, from: 'Barcode printer')
    fill_in('Tubes required', with: tubes)
  end

  def labels_sent_message(count)
    "Your #{count} label(s) have been sent to printer #{printer.name}"
  end

  before do
    SampleManifestExcel.configure do |config|
      config.folder = File.join('spec', 'data', 'sample_manifest_excel')
      config.load!
    end
    create(:sample_tube_purpose, name: 'Standard sample')
    stub_request(:post, LabelPrinter::PmbClient.print_job_url)
    login_user user
    visit(study_path(study))
    click_link('Sample Manifests')
  end

  it 'creates a tube manifest and prints only the first label' do
    fill_in_tube_manifest(2)
    check('Print only the first label')
    click_button('Create manifest and print labels')
    expect(page).to have_text(labels_sent_message(1))
  end

  it 'creates a tube manifest and prints a 2D barcode' do
    fill_in_tube_manifest(1)
    check('Print only the first label')
    select('2D Barcode (with human readable barcode encoded)',
           from: 'Barcode type')
    click_button('Create manifest and print labels')
    expect(page).to have_text(labels_sent_message(1))
  end

  it 'creates a tube manifest and prints all the labels' do
    fill_in_tube_manifest(2)
    click_button('Create manifest and print labels')
    expect(page).to have_text(labels_sent_message(2))
  end
end
