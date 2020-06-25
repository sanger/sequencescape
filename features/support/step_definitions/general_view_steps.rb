# frozen_string_literal: true

When /^I fill in "([^"]+)" with the human barcode "(..)(.+)."$/ do |field, prefix, number|
  step(%Q{I fill in "#{field}" with "#{Barcode.calculate_barcode(prefix, number.to_i)}"})
end
