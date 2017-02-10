# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2014,2015,2016 Genome Research Ltd.

ApiApplication.new(
  name: 'Default Application',
  key: configatron.api.authorisation_code,
  contact: configatron.sequencescape_email,
  description: 'Import of the original authorisation code and privileges to maintain compatibility while systems are migrated.',
  privilege: 'full'
).save(validate: false)
