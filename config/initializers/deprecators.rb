# frozen_string_literal: true

# Create a custom deprecator
Rails.application.deprecators[:sequencescape] = ActiveSupport::Deprecation.new('14.53.0', 'Sequencescape')
