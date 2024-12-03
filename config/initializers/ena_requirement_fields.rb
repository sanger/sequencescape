# frozen_string_literal: true
EBI_REQUIREMENT_FIELDS = YAML.load(File.open(Rails.root.join('config/ena_requirement_fields.yml')))
