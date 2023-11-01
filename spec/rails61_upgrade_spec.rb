# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Rails61_upgrade', type: :model do

  it 'plate_sample_manifest_with_manifest_assets factory should be valid' do
    manifest = create(:plate_sample_manifest_with_manifest_assets)
    expect(manifest.sample_manifest_assets).to be_present
  end
end