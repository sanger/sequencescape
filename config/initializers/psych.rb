# frozen_string_literal: true

Rails.application.configure do
  # Allow YAML columns to contain HashWithIndifferentAccess objects by default
  ActiveRecord.yaml_column_permitted_classes += [ActiveSupport::HashWithIndifferentAccess]
end
