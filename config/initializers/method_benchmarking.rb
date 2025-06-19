# frozen_string_literal: true
if Rails.env.development?
  benchmarking_classes = [
    # Add here any classes you want to benchmark in local
    # Note: Remember to start the process with the env var RAILS_LOG_TO_FILE set to true
  ]

  if benchmarking_classes.length.positive?
    Rails.logger.debug 'Benchmarking methods from classes:'
    benchmarking_classes.each do |klass|
      Rails.logger.debug { "* Benchmarking <#{klass.name}>" }
      klass.extend MethodBenchmarking
      (klass.methods - [Object.methods].flatten).sort.compact.uniq.each do |method_name|
        next unless klass.method_defined?(method_name)

        klass.instance_eval { benchmark_method method_name, tag: 'configured_at_init' }
      end
    end
  end
end
