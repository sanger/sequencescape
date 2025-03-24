# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sdb::SampleManifestsController do

  describe 'GET #new' do
    before do
      @user = FactoryBot.create(:user, swipecard_code: '123456')
      @user.grant_administrator
      session[:user] = @user.id
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
        post :create,
          params: {
            sample_manifest: {
              template: "tube_default",
              purpose_id: purpose.id,
              study_id: study.id,
              supplier_id: supplier.id,
              count: 1,
              barcode_printer: 'xyz',
              barcode_type: '2D Barcode',
              only_first_label: '0',
            },
            asset_type: '1dtube'
          }
      end

      it 'generates a new sample manifest' do
        expect(SampleManifest.count).to eq(sample_manifests + 1)
      end
    end
  end

end