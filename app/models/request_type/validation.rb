# frozen_string_literal: true
# This is used when validating request options when the submission is made, and before it is actually built.
# Unfortunately things have gotten a little tangled around this area, and a heavy refactor is required.
module RequestType::Validation
  def delegate_validator
    DelegateValidation::CompositeValidator.construct(request_class.delegate_validator, request_type_validator)
  end

  def create_validator(request_type)
    Class.new(RequestTypeValidator) do
      request_type.request_type_validators.each do |validator|
        message =
          "is '%<value>s' should be #{
            validator.valid_options.to_sentence(last_word_connector: ', or ', two_words_connector: ' or ')
          }"
        vro = :"#{validator.request_option}"
        delegate_attribute(vro, to: :target, default: validator.default, type_cast: validator.type_cast)
        validates vro,
                  inclusion: {
                    in: validator.valid_options,
                    if: :"#{validator.request_option}_needs_checking?",
                    message:,
                    allow_blank: validator.allow_blank?
                  }
      end
    end
  end

  def request_type_validator
    request_type = self
    create_validator(request_type).tap { |sub_class| sub_class.request_type = request_type }
  end

  class RequestTypeValidator < DelegateValidation::Validator
    class_attribute :request_type, instance_writer: false
    request_type = nil

    def library_types_present?
      request_type.library_types.present?
    end
  end
end
