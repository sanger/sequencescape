# frozen_string_literal: true

FactoryBot.define do
  factory :qc_result do
    asset
    key 'Molarity'
    value '5.43'
    units 'nM'
    cv 2.34
    assay_type 'qPCR'
    assay_version '1.0'

    factory :qc_result_volume do
      key 'volume'
      value '50'
      units 'ul'
    end

    factory :qc_result_concentration do
      key 'concentration'
      value '50'
      units 'ng/ul'
    end

    factory :qc_result_molarity do
      key 'molarity'
      value '5.43'
      units 'nM'
    end

    factory :qc_result_rin do
      key 'RIN'
      value '50'
      units 'RIN'
    end

    factory :qc_result_snp_count do
      key 'snp_count'
      value '100'
      units 'bases'
    end
  end
end
