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
                 barcode_type: '2D Barcode (with human readable barcode encoded)',
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

  describe 'POST #print_labels' do
    let!(:user) { create(:user, swipecard_code: '123456') }

    before do
      user.grant_administrator
      session[:user] = user.id
      request.env['HTTP_REFERER'] = '/'
    end

    context 'when printing labels for a plate manifest' do
      let!(:sample_manifest) { create(:sample_manifest, asset_type: 'plate') }
      let(:print_job) { instance_double(LabelPrinter::PrintJob) }
      let(:printer) { 'printer_1' }

      before do
        allow(LabelPrinter::PrintJob).to receive(:new).and_return(print_job)
        allow(print_job).to receive_messages(execute: true, success: 'Printed')
        allow(controller).to receive(:redirect_back_or_to)
      end

      it 'prints successfully' do # rubocop:disable RSpec/MultipleExpectations
        post :print_labels,
             params: {
               id: sample_manifest.id,
               printer: 'printer_1'
             }

        expect(flash[:notice]).to eq('Printed')
        expect(controller).to have_received(:redirect_back_or_to)
      end
    end

    context 'when printing labels for a tube manifest with 2D barcodes' do
      subject(:make_request) do
        post :print_labels,
             params: {
               id: sample_manifest.id,
               printer: 'printer_1',
               barcode_type: '2D Barcode'
             }
      end

      let!(:sample_manifest) { create(:sample_manifest, asset_type: '1dtube') }
      let(:print_job) { instance_double(LabelPrinter::PrintJob) }

      before do
        allow(controller).to receive(:label_template_for_2d_barcodes).and_return('2d_template')
        allow(LabelPrinter::PrintJob).to receive(:new).and_return(print_job)
        allow(print_job).to receive_messages(execute: true, success: 'Printed')
        allow(controller).to receive(:redirect_back_or_to)
        make_request
      end

      it 'passes the 2D label template to the print job' do
        expect(LabelPrinter::PrintJob).to have_received(:new).with(
          'printer_1',
          LabelPrinter::Label::SampleManifestRedirect,
          hash_including(
            sample_manifest: sample_manifest,
            label_template_name: '2d_template',
            barcode_type: '2D Barcode'
          )
        )
      end

      it 'prints successfully' do # rubocop:disable RSpec/MultipleExpectations
        expect(flash[:notice]).to eq('Printed')
        expect(controller).to have_received(:redirect_back_or_to)
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
