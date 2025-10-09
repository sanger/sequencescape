# frozen_string_literal: true

Rails.application.config.disable_animations = ENV.fetch('DISABLE_ANIMATIONS', false).present?
