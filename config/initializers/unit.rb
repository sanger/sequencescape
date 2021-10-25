# frozen_string_literal: true

# Unit: https://github.com/olbrich/ruby-units
# Unit provides a library for coupling together scalar values and their units,
# allowing conversion where applicable. This file adds custom units, which are
# not available in the standard library.

# RIN stands for RNA Integrity Number and is a measure of RNA quality based on
# how much fragmentation it appears to have undergone. At time of writing
# it is provided by the Agilent Bioanalyser.
# Strictly speaking RIN does not have any units, and is defined here to provide
# consistency across our various QC systems.
# http://gene-quantification.net/RIN.pdf
Unit.define('RIN') do |rin|
  rin.scalar = 1
  rin.aliases = %w[RIN rin] # array of synonyms for the unit
  rin.kind = :rna_integrity
end

Unit.define('cells') do |cells|
  cells.scalar = 1
  cells.display_name = 'cells/ml'
end

Unit.define('percentage') do |percentage|
  percentage.scalar = 1
  percentage.aliases = %w[percentage %]
end
