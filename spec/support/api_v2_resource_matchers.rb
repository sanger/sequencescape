# frozen_string_literal: true

module ApiV2AttributeMatchers
  RSpec::Matchers.define :have_readonly_attribute do |attribute|
    description { "have read-only attribute `#{attribute}`" }

    failure_message { "expected #{resource.class.name.demodulize} to #{description}" }
    failure_message_when_negated { "expected #{resource.class.name.demodulize} not to #{description}" }

    match do |resource|
      expect(resource).to have_attribute attribute
      expect(resource).to have_a_readonly_field attribute
    end
  end

  RSpec::Matchers.define :have_readwrite_attribute do |attribute|
    description { "have read-write attribute `#{attribute}`" }

    failure_message { "expected #{resource.class.name.demodulize} to #{description}" }
    failure_message_when_negated { "expected #{resource.class.name.demodulize} not to #{description}" }

    match do |resource|
      expect(resource).to have_attribute attribute
      expect(resource).to have_a_writable_field attribute
    end
  end

  RSpec::Matchers.define :have_writeonly_attribute do |attribute|
    description { "have write-only attribute `#{attribute}`" }

    failure_message { "expected #{resource.class.name.demodulize} to #{description}" }
    failure_message_when_negated { "expected #{resource.class.name.demodulize} not to #{description}" }

    match do |resource|
      expect(resource).not_to have_attribute attribute
      expect(resource).to have_a_writable_field attribute
    end
  end

  RSpec::Matchers.define :have_write_once_attribute do |attribute|
    description { "have write-once attribute `#{attribute}`" }

    failure_message { "expected #{resource.class.name.demodulize} to #{description}" }
    failure_message_when_negated { "expected #{resource.class.name.demodulize} not to #{description}" }

    match do |resource|
      expect(resource).to have_attribute attribute
      expect(resource).to have_a_write_once_field attribute
    end
  end
end

module ApiV2RelationshipMatchers
  RSpec::Matchers.define :have_a_readonly_has_one do |field, class_name|
    description do
      desc_text = "have a read-only has_one field `#{field}`"
      return desc_text unless class_name

      desc_text + " with class name `#{class_name}`"
    end

    failure_message { "expected #{resource.class.name.demodulize} to #{description}" }
    failure_message_when_negated { "expected #{resource.class.name.demodulize} not to #{description}" }

    match do |resource|
      expect(resource).to have_one(field).with_class_name(class_name)
      expect(resource).to have_a_readonly_field field
    end
  end

  RSpec::Matchers.define :have_a_writable_has_one do |field, class_name|
    description do
      desc_text = "have a writable has_one field `#{field}`"
      return desc_text unless class_name

      desc_text + " with class name `#{class_name}`"
    end

    failure_message { "expected #{resource.class.name.demodulize} to #{description}" }
    failure_message_when_negated { "expected #{resource.class.name.demodulize} not to #{description}" }

    match do |resource|
      expect(resource).to have_one(field).with_class_name(class_name)
      expect(resource).to have_a_writable_field field
    end
  end

  RSpec::Matchers.define :have_a_readonly_has_many do |field, class_name|
    description do
      desc_text = "have a read-only has_many field `#{field}`"
      return desc_text unless class_name

      desc_text + " with class name `#{class_name}`"
    end

    failure_message { "expected #{resource.class.name.demodulize} to #{description}" }
    failure_message_when_negated { "expected #{resource.class.name.demodulize} not to #{description}" }

    match do |resource|
      expect(resource).to have_many(field).with_class_name(class_name)
      expect(resource).to have_a_readonly_field field
    end
  end

  RSpec::Matchers.define :have_a_writable_has_many do |field, class_name|
    description do
      desc_text = "have a writable has_many field `#{field}`"
      return desc_text unless class_name

      desc_text + " with class name `#{class_name}`"
    end

    failure_message { "expected #{resource.class.name.demodulize} to #{description}" }
    failure_message_when_negated { "expected #{resource.class.name.demodulize} not to #{description}" }

    match do |resource|
      expect(resource).to have_many(field).with_class_name(class_name)
      expect(resource).to have_a_writable_field field
    end
  end
end

module ApiV2PrivateMatchers
  RSpec::Matchers.define :have_a_readonly_field do |field|
    description { "have a read-only field `#{field}`" }

    failure_message { "expected #{resource.class.name.demodulize} to #{description}" }
    failure_message_when_negated { "expected #{resource.class.name.demodulize} not to #{description}" }

    match do |resource|
      expect(resource).not_to have_creatable_field field
      expect(resource).not_to have_updatable_field field
    end
  end

  RSpec::Matchers.define :have_a_writable_field do |field|
    description { "have a writable field `#{field}`" }

    failure_message { "expected #{resource.class.name.demodulize} to #{description}" }
    failure_message_when_negated { "expected #{resource.class.name.demodulize} not to #{description}" }

    match do |resource|
      expect(resource).to have_creatable_field field
      expect(resource).to have_updatable_field field
    end
  end

  RSpec::Matchers.define :have_a_write_once_field do |field|
    description { "have a write-once field `#{field}`" }

    failure_message { "expected #{resource.class.name.demodulize} to #{description}" }
    failure_message_when_negated { "expected #{resource.class.name.demodulize} not to #{description}" }

    match do |resource|
      expect(resource).to have_creatable_field field
      expect(resource).not_to have_updatable_field field
    end
  end
end
