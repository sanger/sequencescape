# frozen_string_literal: true

# Factory for input values of global section of Ultima sample sheets.
FactoryBot.define do
  factory :ultima_global do
    name { 'Initial' }
    application { 'WGS native gDNA' }
    sequencing_recipe { 'UG_116cycles_Baseline_1.8.5.2' }
    analysis_recipe { 'wgs1' }
  end
end
