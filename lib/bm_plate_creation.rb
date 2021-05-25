# frozen_string_literal: true

# Benchmark plate creation. Used initially in the well creation optimization.
# https://github.com/sanger/sequencescape/pull/2964/commits/bb9d6741c7fea32cd9236644622312342bdcb181
#
# Usage:
# bundle exec rails runner ./lib/bm_plate_creation.rb
#
# Output example:
# Rehearsal ----------------------------------------------
# construct!   0.468223   0.034742   0.515974 (  0.693562)
# ------------------------------------- total: 0.515974sec

#                  user     system      total        real
# construct!   0.299942   0.004221   0.304163 (  0.355552)
#
# If you wish to compare with new implementations you can add calls to
# an alternative factory, eg:
#
# x.report('create_by_magic!') { TIMES.times { purpose.create_by_magic! } }
#

TIMES = 5

purpose = PlatePurpose.first

Rails.logger.level = :warn

Benchmark.bmbm { |x| x.report('construct!') { TIMES.times { purpose.create! } } }
