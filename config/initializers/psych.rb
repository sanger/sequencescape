# frozen_string_literal: true

Rails.application.configure do
  # Fix for Psych::DisallowedClass: Tried to load unspecified class
  config.active_record.yaml_column_permitted_classes =
    Array(config.active_record.yaml_column_permitted_classes) +
    %w[
      Symbol
      ActiveSupport::HashWithIndifferentAccess
      ActiveSupport::TimeWithZone
      ActiveSupport::TimeZone
      HashWithIndifferentAccess
      RequestType::Validator::ArrayWithDefault
      RequestType::Validator::LibraryTypeValidator
      RequestType::Validator::FlowcellTypeValidator
      ActionController::Parameters
      Set
      Range
      FieldInfo
      Time
    ]
end
