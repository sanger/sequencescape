# frozen_string_literal: true

file_path = Rails.root.join('config/ena_requirement_fields.yml')

if File.exist?(file_path)
  EBI_REQUIREMENT_FIELDS = YAML.load(File.open(file_path))
else
  Rails.logger.warn "File #{file_path} does not exist"
end
