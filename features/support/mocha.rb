# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

# This file is here to ensure that the mock objects get cleared down properly after each scenario.
require 'mocha/api'

World(Mocha::API)

Before do
  mocha_setup
end

After do
  begin
    mocha_verify
  ensure
    mocha_teardown
  end
end
