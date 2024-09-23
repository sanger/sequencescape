# frozen_string_literal: true
#
# Add remaining valid option selections for country of origin
class AddMissingInsdcCountries < ActiveRecord::Migration[6.0]
  def change
    [
      'not applicable: control sample',
      'not applicable: sample group',
      'missing: synthetic construct',
      'missing: lab stock',
      'missing: third party data',
      'missing: data agreement established pre-2023',
      'missing: endangered species',
      'missing: human-identifiable'
    ].each { |name| Insdc::Country.find_or_create_by(name:, sort_priority: -2, validation_state: 0) }
  end
end
