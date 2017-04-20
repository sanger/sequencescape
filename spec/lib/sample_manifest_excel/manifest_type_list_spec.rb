require 'rails_helper'

RSpec.describe SampleManifestExcel::ManifestTypeList, type: :model, sample_manifest_excel: true do
  include SampleManifestExcel::Helpers

  let(:folder) { File.join('spec', 'data', 'sample_manifest_excel', 'extract') }
  let(:yaml) { load_file(folder, 'manifest_types') }
  let(:manifest_type_list) { SampleManifestExcel::ManifestTypeList.new(yaml) }

  it 'creates a list of manifest types' do
    expect(manifest_type_list.count).to eq(yaml.length)
  end

  it 'each manifest type has the correct attributes' do
    yaml.each do |k, v|
      manifest_type = manifest_type_list.find_by(k)
      expect(manifest_type.name).to eq(k)
      expect(manifest_type.heading).to eq(v['heading'])
      expect(manifest_type.columns).to eq(v['columns'])
      expect(manifest_type.asset_type).to eq(v['asset_type'])
    end
  end

  it '#to_a produces a list of headings and names' do
    names_and_headings = manifest_type_list.to_a
    expect(names_and_headings.count).to eq(yaml.length)
    yaml.each do |k, v|
      expect(names_and_headings).to include([v['heading'], k])
    end
  end

  it '#by_asset_type returns a list of manifest types by their asset type' do
    expect(manifest_type_list.by_asset_type('plate').count).to eq(2)
    expect(manifest_type_list.by_asset_type('tube').count).to eq(1)
    expect(manifest_type_list.by_asset_type('dodgy asset type').any?).to be_falsey
    expect(manifest_type_list.by_asset_type(nil).count).to eq(manifest_type_list.count)
  end

  it 'should be comparable' do
    expect(manifest_type_list).to eq(SampleManifestExcel::ManifestTypeList.new(yaml))
    yaml.shift
    expect(manifest_type_list).to_not eq(SampleManifestExcel::ManifestTypeList.new(yaml))
  end
end
