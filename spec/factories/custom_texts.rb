# frozen_string_literal: true

FactoryBot.define do
  factory :custom_text do
    identifier       { nil }
    differential     { nil }
    content_type     { nil }
    content          { nil }
  end
end
