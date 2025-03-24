# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sdb::SampleManifestsController do
  describe 'GET #new' do
    let!(:user) { create(:user, swipecard_code: '123456') }

    before do
      user.grant_administrator
      session[:user] = user.id
    end

    context 'when printing tubes with 2D barcodes' do
      let!(:sample_manifests) { SampleManifest.count }
      let(:study) { create(:study) }
      let(:supplier) { create(:supplier) }
      let(:purpose) { create(:tube_purpose) }

      before do
        SampleManifestExcel.configure do |config|
          config.folder = File.join('spec', 'data', 'sample_manifest_excel')
          config.tag_group = 'My Magic Tag Group'
          config.load!
        end
        allow(LabelPrinter::PrintJob).to receive(:new).and_call_original
        post :create,
             params: {
               sample_manifest: {
                 template: 'tube_default',
                 purpose_id: purpose.id,
                 study_id: study.id,
                 supplier_id: supplier.id,
                 count: 1,
                 barcode_printer: 'xyz',
                 barcode_type: '2D Barcode',
                 only_first_label: '0'
               },
               asset_type: '1dtube'
             }
      end

      it 'generates a new sample manifest' do
        expect(SampleManifest.count).to eq(sample_manifests + 1)
      end

      it 'generates a new sample manifest with the correct attributes' do
        sample_manifest = SampleManifest.last
        expect_correct_attributes(sample_manifest, study, supplier, purpose)
      end

      it 'invokes LabelPrinter::PrintJob.new' do
        expect(LabelPrinter::PrintJob).to have_received(:new).once
      end
    end
  end

  def expect_correct_attributes(sample_manifest, study, supplier, purpose) # rubocop:todo Metrics/AbcSize
    expect(sample_manifest.study_id).to eq(study.id)
    expect(sample_manifest.supplier_id).to eq(supplier.id)
    expect(sample_manifest.purpose_id).to eq(purpose.id)
    expect(sample_manifest.asset_type).to eq('1dtube')
    expect(sample_manifest.rows_per_well).to eq(1)
    expect(sample_manifest.invalid_wells).to eq([])
  end
end
