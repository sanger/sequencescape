# frozen_string_literal: true

# NPG expressed concerns that switching the Sequencescape to Utf8 would result in an
# increase in characters which could not be processed by their pipelines. This validator
# checks that the characters can be represented in latin1, ensuring that we don't make the
# problem worse in the short term.
# This will likely be replaced by more specific validations as we become aware of exactly what
# is supported.
# It has been applied to the key fields that get added to headers and the like.
class Latin1Validator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return true if value.blank?

    value.encode('cp1252')
    return true if value.encode('cp1252').valid_encoding?
  rescue Encoding::UndefinedConversionError => e
    record.errors[attribute] <<
      (
        options[:message] ||
          "contains unsupported characters (non-latin characters), remove or replace them: #{e.error_char}"
      )
  end
end
