# frozen_string_literal: true

FactoryGirl.define do
  factory :qc_result do
    asset
    key 'Molarity'
    value '5.43'
    units 'nM'
    cv 2.34
    assay_type 'qPCR'
    assay_version '1.0'
  end
end
