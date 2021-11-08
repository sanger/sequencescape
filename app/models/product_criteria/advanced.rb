# frozen_string_literal: true
# Advanced Product Criteria can have 'unprocessable' thresholds
# as well as fails.
class ProductCriteria::Advanced < ProductCriteria::Basic
  attr_reader :qc_decision

  STATE_ORDER = %w[failed unprocessable].freeze

  TARGET_PLATE_PURPOSES = 'target_plate_purposes'

  CONFIG_KEYS = [TARGET_PLATE_PURPOSES].freeze

  class << self
    def headers(configuration)
      (configuration.slice(*STATE_ORDER).values.reduce(&:merge).keys + [:comment]).uniq
    end
  end

  def invalid(attribute, message, decision)
    @qc_decision = decision
    @comment << (message % attribute.to_s.humanize)
    @comment.uniq!
  end

  # rubocop:todo Metrics/MethodLength
  def assess! # rubocop:todo Metrics/AbcSize
    @qc_decision = 'passed'
    STATE_ORDER.each do |decision|
      params
        .fetch(decision, [])
        .each do |attribute, comparisons|
          value = fetch_attribute(attribute)
          values[attribute] = value

          if value.blank? && comparisons.present?
            invalid(attribute, '%s has not been recorded', decision)
            next
          end

          comparisons.each do |comparison, target|
            value.send(method_for(comparison), target) || invalid(attribute, message_for(comparison), decision)
          end
        end
    end
  end
  # rubocop:enable Metrics/MethodLength
end
