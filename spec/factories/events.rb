# frozen_string_literal: true

FactoryGirl.define do
  factory :event do
    family          ''
    content         ''
    message         ''
    eventful_type   ''
    eventful_id     ''
    type            'Event'
  end
end
