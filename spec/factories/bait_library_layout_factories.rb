# frozen_string_literal: true

FactoryBot.define do
  factory :bait_library_layout do
    user
    plate
    layout { {
      'Human all exon 50MB' => %w[A1 A2 B1 B2 C1 C2 D1 D2 E1 F1 G1 H1]
    } }
  end
end
