# frozen_string_literal: true

Rails.application.configure do
  # Allow legacy YAML deserialization for ActiveRecord serialized columns
  # Ideally replace with `permitted_classes`, such as those used in the list below:
  #   Symbol
  #   ActiveSupport::HashWithIndifferentAccess
  #   ActiveSupport::TimeWithZone
  #   ActiveSupport::TimeZone
  #   HashWithIndifferentAccess
  #   RequestType::Validator::ArrayWithDefault
  #   RequestType::Validator::LibraryTypeValidator
  #   RequestType::Validator::FlowcellTypeValidator
  #   ActionController::Parameters
  #   Set
  #   Range
  #   FieldInfo
  #   Time
  config.active_record.use_yaml_unsafe_load = true
end
