# frozen_string_literal: true

TIMES = 5

purpose = PlatePurpose.first

Rails.logger.level = :warn

Benchmark.bmbm do |x|
  x.report('construct!') { TIMES.times { purpose.create! } }
end
