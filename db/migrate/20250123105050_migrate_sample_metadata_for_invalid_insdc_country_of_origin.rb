# frozen_string_literal: true
# Migrates the data related to invalid INSDC countries of origin to their current equivalent
# See DisableInvalidInsdcCountries migration for more details
class MigrateSampleMetadataForInvalidInsdcCountryOfOrigin < ActiveRecord::Migration[7.0]
  def change
    sample_metadata =
      Sample::Metadata.where(country_of_origin: ['not applicable: control sample', 'not applicable: sample group'])

    sample_metadata.each do |sm|
      if sm.country_of_origin == 'not applicable: control sample'
        sm.update!(country_of_origin: 'missing: control sample')
      elsif sm.country_of_origin == 'not applicable: sample group'
        sm.update!(country_of_origin: 'missing: sample group')
      end
    end
  end
end
