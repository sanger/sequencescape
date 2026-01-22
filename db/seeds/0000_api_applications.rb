# frozen_string_literal: true

throw StandardError('Your database is already seeded.') if ApiApplication.find_by(name: 'Default Application')

ApiApplication.new(
  name: 'Default Application',
  key: configatron.api.authorisation_code,
  contact: configatron.sequencescape_email,
  description:
    'Import of the original authorisation code and privileges to maintain compatibility while systems are migrated.',
  privilege: 'full'
).save(validate: false)
