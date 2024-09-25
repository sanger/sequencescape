# frozen_string_literal: true

# Control the defaults to use. Please remember to update sample_checklist if necessary
INSDC_COUNTRIES_DEFAULTS ||= {
  ena_root: 'https://www.ebi.ac.uk/ena/browser/api/xml/',
  sample_checklist: 'ERC000011'
}.freeze

# Sets the default priorities. Resisting the temptation to put this in a yaml file for now.
# Higher priorities are sorted towards the top of the list
INSDC_COUNTRIES_PRIORITIES ||= {
  'not provided' => 2,
  'United Kingdom' => 1,
  'not applicable' => -1,
  'not collected' => -1,
  'restricted access' => -1
}.freeze

namespace :insdc do
  namespace :countries do
    desc 'Download the sample sheet with the accession number specified by [sample_checklist] ' \
           "(#{INSDC_COUNTRIES_DEFAULTS[:sample_checklist]} by default)"
    task :download, %i[sample_checklist ean_root] => :environment do |_t, args|
      args.with_defaults(INSDC_COUNTRIES_DEFAULTS)
      Insdc::ImportCountries.new(**args.to_h, priorities: INSDC_COUNTRIES_PRIORITIES).download
    end

    desc 'Download and import countries from the sample sheet with the accession number specified by ' \
           "[sample_checklist] (#{INSDC_COUNTRIES_DEFAULTS[:sample_checklist]} by default)"
    task :import, %i[sample_checklist ean_root] => :environment do |_t, args|
      args.with_defaults(INSDC_COUNTRIES_DEFAULTS)
      Insdc::ImportCountries.new(**args.to_h, priorities: INSDC_COUNTRIES_PRIORITIES).import
    end
  end
end
