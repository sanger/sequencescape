#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2015 Genome Research Ltd.

module Submission::RequestOptionsBehaviour
  def self.included(base)
    base.class_eval do
      serialize :request_options, ActiveSupport::HashWithIndifferentAccess
      validate :check_request_options, :if => :request_options_changed?
    end
  end

  def request_options=(options)
    return super(options.nested_under_indifferent_access) if options.is_a?(Hash)
    super
  end

  def check_request_options
    check_multipliers_are_valid
  end
  private :check_request_options

  def check_multipliers_are_valid
    multipliers = request_options.try(:[], :multiplier)
    return if multipliers.blank?      # We're ok with nothing being specified!

    # TODO[xxx]: should probably error if they've specified a request type that isn't being used
    errors.add(:request_options, 'negative multiplier supplied')  if multipliers.values.map(&:to_i).any?(&:negative?)
    errors.add(:request_options, 'zero multiplier supplied')      if multipliers.values.map(&:to_i).any?(&:zero?)
    return false unless errors.empty?
  end
  private :check_multipliers_are_valid
end
