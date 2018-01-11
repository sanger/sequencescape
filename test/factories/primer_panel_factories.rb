FactoryGirl.define do
  factory :primer_panel do
    sequence(:name) { |i| "Primer Panel #{i}" }
    snp_count 1
    sequence(:programs) { |n| { 'pcr 1' => { 'name' => "pcr1 program #{n}", 'duration' => 45 },
                                'pcr 2' => { 'name' => "pcr2 program #{n}" , 'duration' => 20 }
    } }
  end
end
