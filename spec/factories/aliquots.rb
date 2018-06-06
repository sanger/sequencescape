# frozen_string_literal: true

FactoryBot.define do
  factory :aliquot, aliases: [:tagged_aliquot, :dual_tagged_aliquot] do
    sample
    study
    project
    tag
    tag2
    receptacle

    factory :untagged_aliquot do
      tag  nil
      tag2 nil
    end

    factory :single_tagged_aliquot do
      tag
      tag2 nil
    end

    factory :minimal_aliquot do
      study nil
      project nil
      tag nil
      tag2 nil
    end
  end

  factory :spiked_buffer do
    name { generate :asset_name }
    samples { [Sample.find_or_create_by!(name: 'phiX_for_spiked_buffers')] }
    volume 50
  end
end
