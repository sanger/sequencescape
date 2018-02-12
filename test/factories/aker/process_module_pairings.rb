FactoryGirl.define do
  factory :aker_process_module_pairing, class: Aker::ProcessModulePairing do
    process { create(:aker_process) }
    from_step { create(:aker_process_module) }
    to_step { create(:aker_process_module) }
  end
end
