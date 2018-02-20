require 'rails_helper'

RSpec.describe Aker::ProcessModule, type: :model, aker: true do
  it 'is not valid without a name' do
    expect(build(:aker_process_module, name: nil)).to_not be_valid
  end

  it 'is not valid without a unique name' do
    process_module = create(:aker_process_module)
    expect(build(:aker_process_module, name: process_module.name)).to_not be_valid
  end
end
