module Submission::RequestOptionsBehaviour # rubocop:todo Style/Documentation
  # Ensures the hash gets loaded with indifferent access.
  # Note: We can't just specify the class, as otherwise legacy
  # hashes throw an exception
  class HashWrapper
    def self.load(hash_yaml)
      return hash_yaml if hash_yaml.nil?

      YAML.load(hash_yaml)
    end

    def self.dump(hash)
      YAML.dump(hash)
    end
  end

  def self.included(base)
    base.class_eval do
      serialize :request_options, HashWrapper
      validate :check_request_options, if: :request_options_changed?
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

  # rubocop:todo Metrics/PerceivedComplexity
  # rubocop:todo Metrics/AbcSize
  def check_multipliers_are_valid # rubocop:todo Metrics/CyclomaticComplexity
    multipliers = request_options.try(:[], :multiplier)
    return if multipliers.blank? # We're ok with nothing being specified!

    # TODO[xxx]: should probably error if they've specified a request type that isn't being used
    errors.add(:request_options, 'negative multiplier supplied') if multipliers.values.map(&:to_i).any?(&:negative?)
    errors.add(:request_options, 'zero multiplier supplied') if multipliers.values.map(&:to_i).any?(&:zero?)
    return false unless errors.empty?
  end

  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/PerceivedComplexity
  private :check_multipliers_are_valid
end
