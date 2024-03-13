# frozen_string_literal: true

# While our database support utf8mb4, the same isn't true for the warehouse
# and there may be even tighter constraints downstream in NPG. This allows
# us to constrain affected fields until the downstream processes add support.
# This validator produces an error message listing the problem characters.
#
# utf8mb3 is the subset of utf8 which can be represented in 3 bytes or fewer
# and is what is supported when the mysql character-set is set to utf8. Typically
# if covers the majority of language characters, but excludes emoji
#
# A similar validator should be added for any tighter restrictions that may
# be applied for other fields.
class Utf8mb3Validator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return true if value.blank?

    invalid_characters = value.chars.select { |c| c.bytesize > 3 }
    return true if invalid_characters.empty?

    record.errors.add(attribute, options[:message] ||
      "contains supplementary characters (eg. emoji), remove or replace them: #{invalid_characters.to_sentence}")
  end
end
