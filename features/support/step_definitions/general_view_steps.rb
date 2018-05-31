# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

When /^I fill in "([^\"]+)" with the human barcode "(..)(.+)."$/ do |field, prefix, number|
  step(%Q{I fill in "#{field}" with "#{Barcode.calculate_barcode(prefix, number.to_i)}"})
end
