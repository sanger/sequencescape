# frozen_string_literal: true

FactoryBot.define do
  sequence :sanger_sample_id do |n|
    "sample_#{n}"
  end
end
