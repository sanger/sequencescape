# frozen_string_literal: true

module ApiV2AttributeMatchers
  RSpec::Matchers.define :have_readonly_attribute do |attribute|
    description { "have read-only attribute `#{attribute}`" }

    failure_message { "expected to #{description}" }
    failure_message_when_negated { "expected not to #{description}" }

    match do |resource|
      expect(resource).to have_attribute attribute
      expect(resource).to have_a_readonly_field attribute
    end
  end

  RSpec::Matchers.define :have_readwrite_attribute do |attribute|
    description { "have read-write attribute `#{attribute}`" }

    failure_message { "expected to #{description}" }
    failure_message_when_negated { "expected not to #{description}" }

    match do |resource|
      expect(resource).to have_attribute attribute
      expect(resource).to have_a_writable_field attribute
    end
  end

  RSpec::Matchers.define :have_writeonly_attribute do |attribute|
    description { "have write-only attribute `#{attribute}`" }

    failure_message { "expected to #{description}" }
    failure_message_when_negated { "expected not to #{description}" }

    match do |resource|
      expect(resource).not_to have_attribute attribute
      expect(resource).to have_a_writable_field attribute
    end
  end

  RSpec::Matchers.define :have_write_once_attribute do |attribute|
    description { "have write-once attribute `#{attribute}`" }

    failure_message { "expected to #{description}" }
    failure_message_when_negated { "expected not to #{description}" }

    match do |resource|
      expect(resource).to have_attribute attribute
      expect(resource).to have_a_write_once_field attribute
    end
  end
end

module ApiV2RelationshipMatchers
  def generate_description(type_description, field, class_name)
    desc_text = "have a #{type_description} field `#{field}`"
    return desc_text unless class_name

    desc_text + " with class name `#{class_name}`"
  end

  RSpec::Matchers.define :have_a_readonly_has_one do |field|
    chain(:with_class_name) { |class_name| @class_name = class_name }
    description { generate_description('read-only has_one', field, @class_name) }
    failure_message { "expected to #{description}" }
    failure_message_when_negated { "expected not to #{description}" }

    match do |resource|
      expect(resource).to have_a_readonly_field field

      relationship_matcher = JSONAPI::Resources::Matchers::Relationship.new(:have_one, field)
      relationship_matcher.expected_class_name = @class_name
      relationship_matcher.matches?(resource)
    end
  end

  RSpec::Matchers.define :have_a_writable_has_one do |field|
    chain(:with_class_name) { |class_name| @class_name = class_name }
    description { generate_description('writable has_one', field, @class_name) }
    failure_message { "expected to #{description}" }
    failure_message_when_negated { "expected not to #{description}" }

    match do |resource|
      expect(resource).to have_a_writable_field field

      relationship_matcher = JSONAPI::Resources::Matchers::Relationship.new(:have_one, field)
      relationship_matcher.expected_class_name = @class_name
      relationship_matcher.matches?(resource)
    end
  end

  RSpec::Matchers.define :have_a_write_once_has_one do |field|
    chain(:with_class_name) { |class_name| @class_name = class_name }
    description { generate_description('write-once has_one', field, @class_name) }
    failure_message { "expected to #{description}" }
    failure_message_when_negated { "expected not to #{description}" }

    match do |resource|
      expect(resource).to have_a_write_once_field field

      relationship_matcher = JSONAPI::Resources::Matchers::Relationship.new(:have_one, field)
      relationship_matcher.expected_class_name = @class_name
      relationship_matcher.matches?(resource)
    end
  end

  RSpec::Matchers.define :have_a_readonly_has_many do |field|
    chain(:with_class_name) { |class_name| @class_name = class_name }
    description { generate_description('read-only has_many', field, @class_name) }
    failure_message { "expected to #{description}" }
    failure_message_when_negated { "expected not to #{description}" }

    match do |resource|
      expect(resource).to have_a_readonly_field field

      relationship_matcher = JSONAPI::Resources::Matchers::Relationship.new(:have_many, field)
      relationship_matcher.expected_class_name = @class_name
      relationship_matcher.matches?(resource)
    end
  end

  RSpec::Matchers.define :have_a_writable_has_many do |field|
    chain(:with_class_name) { |class_name| @class_name = class_name }
    description { generate_description('writable has_many', field, @class_name) }
    failure_message { "expected to #{description}" }
    failure_message_when_negated { "expected not to #{description}" }

    match do |resource|
      expect(resource).to have_a_writable_field field

      relationship_matcher = JSONAPI::Resources::Matchers::Relationship.new(:have_many, field)
      relationship_matcher.expected_class_name = @class_name
      relationship_matcher.matches?(resource)
    end
  end

  RSpec::Matchers.define :have_a_write_once_has_many do |field|
    chain(:with_class_name) { |class_name| @class_name = class_name }
    description { generate_description('write-once has_many', field, @class_name) }
    failure_message { "expected to #{description}" }
    failure_message_when_negated { "expected not to #{description}" }

    match do |resource|
      expect(resource).to have_a_write_once_field field

      relationship_matcher = JSONAPI::Resources::Matchers::Relationship.new(:have_many, field)
      relationship_matcher.expected_class_name = @class_name
      relationship_matcher.matches?(resource)
    end
  end
end

module ApiV2PrivateMatchers
  RSpec::Matchers.define :have_a_readonly_field do |field|
    match do |resource|
      expect(resource).not_to have_creatable_field field
      expect(resource).not_to have_updatable_field field
    end
  end

  RSpec::Matchers.define :have_a_writable_field do |field|
    match do |resource|
      expect(resource).to have_creatable_field field
      expect(resource).to have_updatable_field field
    end
  end

  RSpec::Matchers.define :have_a_write_once_field do |field|
    match do |resource|
      expect(resource).to have_creatable_field field
      expect(resource).not_to have_updatable_field field
    end
  end
end
