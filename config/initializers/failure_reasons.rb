# frozen_string_literal: true
FAILURE_REASONS = YAML.load(File.open("#{Rails.root}/config/failure_reasons.yml"))
