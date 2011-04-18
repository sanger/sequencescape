module Submission::RequestOptionsBehaviour
  def self.included(base)
    base.class_eval do
      serialize :request_options
      validate :check_request_options, :if => :request_options_changed?
    end
  end

  def check_request_options
    check_multipliers_are_valid
  end
  private :check_request_options

  def check_multipliers_are_valid
    multipliers = self.request_options.try(:[], :multiplier)
    return if multipliers.blank?      # We're ok with nothing being specified!

    # TODO[xxx]: should probably error if they've specified a request type that isn't being used
    errors.add(:request_options, 'negative multiplier supplied')  if multipliers.values.map(&:to_i).any? { |v| v < 0 }
    errors.add(:request_options, 'zero multiplier supplied')      if multipliers.values.map(&:to_i).any?(&:zero?)
  end
  private :check_multipliers_are_valid
end
