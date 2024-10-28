# frozen_string_literal: true

FactoryBot.define do
  factory :pooled_request, class: 'PreCapturePool::PooledRequest' do
    request { build(:request) }
    pre_capture_pool { build(:pre_capture_pool) }
  end
end
