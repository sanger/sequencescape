#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
module RequestType::Validation

  def delegate_validator
    DelegateValidation::CompositeValidator::CompositeValidator(request_class.delegate_validator,request_type_validator)
  end

  def request_type_validator
    request_type = self

    Class.new(RequestTypeValidator) do
      request_type.request_type_validators.each do |validator|
        message = "is '%{value}' should be #{validator.valid_options.to_sentence(:last_word_connector=>' or ')}"
        vro = :"#{validator.request_option}"
        delegate_attribute(vro, :to => :target, :default => validator.default, :type_cast => validator.type_cast)
        validates_inclusion_of vro, :in => validator.valid_options, :if => :"#{validator.request_option}_needs_checking?", :message => message
      end
    end.tap do |sub_class|
      sub_class.request_type =  request_type
    end

  end

  class RequestTypeValidator < DelegateValidation::Validator
    class_attribute :request_type, :instance_writer => false
    request_type =  nil

    def library_types_present?
      request_type.library_types.present?
    end

  end
end
