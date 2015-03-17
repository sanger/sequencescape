#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
##
# Extended validators are used to provide extra validation
# of submission. They are associated with request types
# and will import validation behaviour into submission.
#
# behaviour => the module that will be included in the validator, must respond to validate(submission)
# options   => serialized hash for configuration

class ExtendedValidator < ActiveRecord::Base

  class RequestTypeExtendedValidator < ActiveRecord::Base

    set_table_name('request_types_extended_validators')

    belongs_to :extended_validator
    belongs_to :request_type
    validates_presence_of :extended_validator
    validates_presence_of :request_type

  end

  def after_initialize
    import_behaviour
  end

  def import_behaviour
    return if behaviour.nil?
    behavior_module = "ExtendedValidator::#{behaviour}".constantize
    self.class_eval do
      include(behavior_module)
    end
  end

  has_many :request_type_extened_validators, :dependent => :destroy, :class_name => 'ExtendedValidator::RequestTypeExtendedValidator'
  has_many :request_types, :through => :request_type_extened_validators

  validates_presence_of :behaviour
  serialize :options

  named_scope :for_submission, lambda {|submission|
    {
      :joins => 'INNER JOIN request_types_extended_validators ON request_types_extended_validators.extended_validator_id = extended_validators.id',
      :conditions => {:request_types_extended_validators => { :request_type_id => submission.request_types }}
    }
  }
end
