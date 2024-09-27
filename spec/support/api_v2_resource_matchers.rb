# frozen_string_literal: true

module ApiV2Matchers
  RSpec::Matchers.define :have_readonly_attribute do |attribute|
    description { "have read-only attribute `#{attribute}`" }

    failure_message { "expected #{resource.class.name.demodulize} to #{description}" }
    failure_message_when_negated { "expected #{resource.class.name.demodulize} not to #{description}" }

    match do |resource|
      expect(resource).to have_attribute attribute
      expect(resource).not_to have_updatable_field attribute
    end
  end

  RSpec::Matchers.define :have_readwrite_attribute do |attribute|
    description { "have read-write attribute `#{attribute}`" }

    failure_message { "expected #{resource.class.name.demodulize} to #{description}" }
    failure_message_when_negated { "expected #{resource.class.name.demodulize} not to #{description}" }

    match do |resource|
      expect(resource).to have_attribute attribute
      expect(resource).to have_updatable_field attribute
    end
  end

  RSpec::Matchers.define :have_writeonly_attribute do |attribute|
    description { "have write-only attribute `#{attribute}`" }

    failure_message { "expected #{resource.class.name.demodulize} to #{description}" }
    failure_message_when_negated { "expected #{resource.class.name.demodulize} not to #{description}" }

    match do |resource|
      expect(resource).not_to have_attribute attribute
      expect(resource).to have_updatable_field attribute
    end
  end
end
