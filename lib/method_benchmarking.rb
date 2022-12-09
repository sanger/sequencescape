# Helper module to generate a log entry with the benchmarking values for a method call
#
# How to use it:
#
# 1. Include this module in a class:
# 2. Add a line benchmark_method with the method you want to wrap for benchmarking:
#
# Eg:
#
#  class A
#    def my_method
#      ...
#    end
#    ...
#    include MethodBenchmarking
#    benchmark_method :my_method, tag: 'my_custom_tag', 
#  end
#
module MethodBenchmarking
  def self.included(klass) 
    klass.instance_eval do
      def benchmark_method(method_name, options = {})
        return if method_name.start_with?('benchmark')
        return if method_name.start_with?('_')
        alias_method :"benchmark_#{method_name}", :"#{method_name}"

        define_method(method_name) do |*args, **kwargs, &block|
          tag = options.has_key?(:tag) ? options[:tag] : DefaultConfig::DEFAULT_TAG

          output = nil
          measure = Benchmark.measure do
            output = send(:"benchmark_#{method_name}", *args, **kwargs, &block)
          end

          selected_caller_location = caller_locations(1,1).first

          selected_caller_location.tap do |loc|
            Rails.logger.debug "PERFORMANCE[#{tag}][#{self.class.name}][#{method_name}]: #{loc.path}:#{loc.lineno} #{measure}"
          end
          output
        end
      end
    end
  end

  module DefaultConfig
    DEFAULT_TAG = 'default'
  end
end