require 'rails_helper'

RSpec.describe SampleManifestExcel::Tags, type: :model, sample_manifest_excel: true do

  describe 'example_data' do

    let(:data) { SampleManifestExcel::Tags::ExampleData.new }

    it 'can produce a list of tags of an appropriate length' do
      tags = data.take(0, 4)
      expect(tags.length).to eq(5)
      expect(tags[0]).to have_key(:tag_oligo)
      expect(tags[0]).to have_key(:tag2_oligo)
      expect(tags[tags.keys.first]).to_not eq(tags[tags.keys.last])
    end

    it 'can produce a list of tags with a duplicate' do
      tags = data.take(0, 4, true)
      expect(tags[tags.keys.first]).to eq(tags[tags.keys.last])
    end
  end
end