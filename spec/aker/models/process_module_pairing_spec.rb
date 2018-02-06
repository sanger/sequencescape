require 'rails_helper'

RSpec.describe Aker::ProcessModulePairing, type: :model, aker: true do
  it 'must have a process' do
    expect(build(:aker_process_module_pairing, process: nil)).to_not be_valid
  end

  it 'can set the default path' do
    expect(build(:aker_process_module_pairing, default_path: true)).to be_default_path
  end

  it 'must have a from step or a to step' do
    expect(build(:aker_process_module_pairing, from_step: nil)).to be_valid
    expect(build(:aker_process_module_pairing, to_step: nil)).to be_valid
    expect(build(:aker_process_module_pairing, from_step: nil, to_step: nil)).to_not be_valid
  end

  it 'when from step or to step is empty should return null' do
    expect(build(:aker_process_module_pairing, from_step: nil).from_step.name).to eq('null')
    expect(build(:aker_process_module_pairing, to_step: nil).to_step.name).to eq('null')
  end
end
