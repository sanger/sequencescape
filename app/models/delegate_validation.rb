#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2014 Genome Research Ltd.
# Delegate validation is all about enabling one class to validate the information within an instance of
# another class.  The case driving this is the ability for a Submission to validate that the request options
# provided by the user are valid for the RequestType instances that the submission is going to use.  In that
# case the RequestType#delegate_validator returns a class that can then be used to validate the request options.
# Because RequestType isn't subclassed it actually delegates to the Request class that it'll instantiate, so
# you can find examples of the delegator stuff in SequencingRequest and LibraryCreationRequest
module DelegateValidation
  def delegate_validation(*args)
    options           = args.extract_options!
    delegation_target = options.delete(:to) or raise StandardError, "Cannot delegate validation without :to!"
    attribute_tag     = options[:as]
    args.push(options)

    validates_each(*args) do |record, attr, value|
      validator = record.send(:"#{delegation_target}_delegate_validator").new(value)
      validator.valid?.tap do
        validator.errors.messages.each do |attrib,message|
          record.errors.add("#{attribute_tag}.#{attrib}",message.join('; '))
        end
      end
    end
  end

  class Validator
    include Validateable

    class DelegateError < ActiveModel::Errors
      def initialize(base,target)
        @base     = base
        @messages = target.errors.messages
      end
    end

    attr_reader :target
    protected :target
    delegate :include_unset_values?, :to => :target


    def self.name
      'Nothing'
    end

    def initialize(target)
      @target = target
    end

    def self.delegate_attribute(*args)
      options   = args.extract_options!
      type_cast = ".#{ options[:type_cast] }"        if options.key?(:type_cast) && options[:type_cast].present?
      default   = " || #{options[:default].inspect}" if options.key?(:default)

      args.each do |attribute|
        line = __LINE__ + 1
        class_eval(%Q{
          def #{attribute}_before_type_cast
            #{options[:to]}.#{attribute} #{default}
          end

          def #{attribute}
            #{attribute}_before_type_cast#{type_cast}
          end

          def #{attribute}_needs_checking?
            #{attribute}_before_type_cast.present? or include_unset_values?
          end
        }, __FILE__, line)
      end
    end
  end

  # A simple validator that is always assumed to be valid.
  class AlwaysValidValidator < Validator
    def valid?
      true
    end
  end

  # A composite validator that will perform multiple validations across several validator classes.
  class CompositeValidator
    include ActiveModel::Validations
    class_attribute :validator_classes, :instance_writer => false

    def self.CompositeValidator(*validator_classes)
      Class.new(CompositeValidator).tap do |sub_class|
        sub_class.validator_classes =  validator_classes
      end
    end

    def initialize(target)
      @target = target
      @validators = self.class.validator_classes.map { |c| c.new(target) }
    end

    def valid?
      # We have to run over all validators to get all error messages, then we can check they're all valid
      return true if @validators.map(&:valid?).all? { |v| v == true }
      @validators.each do |validator|
        errors.messages.merge!(validator.errors.messages)
      end
      false
    end

  end
end

