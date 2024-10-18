# frozen_string_literal: true

# This migration corrects the country list for missing samples/sample groups
# following EBI's checklist https://www.ebi.ac.uk/ena/browser/view/ERC000011
class DisableInvalidInsdcCountries < ActiveRecord::Migration[6.1]
  def change
    # Disable existing invalid countries
    # We don't want to delete them yet in case they are used in existing records and existing manifests.
    ['not applicable: control sample', 'not applicable: sample group'].each do |name|
      Insdc::Country.find_by(name:)&.invalid!
    end

    # Add missing countries
    ['missing: control sample', 'missing: sample group'].each do |name|
      Insdc::Country.find_or_create_by(name: name, sort_priority: -2, validation_state: 0)
    end
  end
end
