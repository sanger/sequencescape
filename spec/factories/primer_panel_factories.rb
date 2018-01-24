# frozen_string_literal: true

FactoryGirl.define do
  factory :primer_panel do
    sequence(:name) { |i| "Primer Panel #{i}" }
    snp_count 1
    programs 'pcr 1' => { 'name' => 'pcr1 program', 'duration' => 45 },
             'pcr 2' => { 'name' => 'pcr2 program', 'duration' => 20 }
  end
end
