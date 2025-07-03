# frozen_string_literal: true
# Helper module to generate a log entry with the benchmarking values for a method call
#
# How to use it:
#
# 1. Extend this module in a class:
# 2. Add a line benchmark_method with the method you want to wrap for benchmarking:
#
# Eg:
#
#  class A
#    def my_method
#      ...
#    end
#    ...
#    extend MethodBenchmarking

#    benchmark_method :my_method, tag: 'my_custom_tag',
#  end
#
module MethodBenchmarking
  # rubocop:disable Metrics/AbcSize
  def benchmark_method(method_name, options = {}) # rubocop:todo Metrics/MethodLength
    return if method_name.start_with?('benchmark', '_')

    alias_method :"benchmark_#{method_name}", :"#{method_name}"

    define_method(method_name) do |*args, **kwargs, &block|
      tag = options.key?(:tag) ? options[:tag] : DefaultConfig::DEFAULT_TAG
      loc = caller_locations(1, 1).first

      output = nil
      measure = Benchmark.measure { output = send(:"benchmark_#{method_name}", *args, **kwargs, &block) }
      line = "PERFORMANCE[#{tag}][#{self.class.name}][#{method_name}]: #{loc.path}:#{loc.lineno} #{measure}"
      Rails.logger.debug line
      output
    end
  end

  # rubocop:enable Metrics/AbcSize

  module DefaultConfig
    DEFAULT_TAG = 'default'
  end
end
