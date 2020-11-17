# frozen_string_literal: true

TIMES = 5

purpose = PlatePurpose.first

Rails.logger.level = :warn

Benchmark.bmbm do |x|
  x.report('legacy_construct') { TIMES.times { purpose.create!(construct_method: :legacy_construct!) } }
  x.report('intermediate_construct') { TIMES.times { purpose.create!(construct_method: :intermediate_construct!) } }
  x.report('construct!') { TIMES.times { purpose.create!(construct_method: :construct!) } }
end
