# frozen_string_literal: true

FactoryBot.define do
  factory :qc_report do
    study
    product_criteria
    exclude_existing { false }
  end

  factory :qc_metric do
    qc_report
    asset            { |a| a.association(:well) }
    qc_decision      { 'passed' }
  end
end
