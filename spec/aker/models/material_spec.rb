require 'rails_helper'
RSpec.describe Aker::Material, type: :model, aker: true do
  context '#update_attributes' do
    let(:sample) {create :sample }
    before do
      sample.sample_metadata.update_attributes(gender: 'Male')
    end
    it 'updates gender' do
      expect(sample.sample_metadata.gender).to eq('Male')
      Aker::Material.new(sample).update_attributes(gender: 'Female')
      sample.sample_metadata.reload
      expect(sample.sample_metadata.gender).to eq('Female')
    end

  end
end