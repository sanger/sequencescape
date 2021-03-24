# frozen_string_literal: true

require 'warren'

Warren.setup(Rails.application.config.warren.deep_symbolize_keys.slice(:type, :config))
