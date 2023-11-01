# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Rails61_upgrade', type: :model do

  it 'plate_sample_manifest_with_manifest_assets factory should be valid' do
    manifest = create(:plate_sample_manifest_with_manifest_assets)
    expect(manifest.sample_manifest_assets).to be_present
  end
  
  # TODO: need to get this working
  context 'validate FactoryBot factories' do
    FactoryBot.factories.each do |factory|

      context "with factory for :#{factory.name}" do
        subject { FactoryBot.build(factory.name) }
        it "is valid" do
          is_valid = subject.valid?
          is_valid.should be_true, subject.errors.full_messages.join(',')
        end
  
      end
    end
  end
 
end