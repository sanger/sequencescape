# frozen_string_literal: true
FAILURE_REASONS = YAML.load(File.open("#{Rails.root.join('config/failure_reasons.yml')}"))
