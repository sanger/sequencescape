if Rails.env.development?
  benchmarking_classes = [
    # Add here any classes you want to benchmark in local
  ]

  if benchmarking_classes.length > 0
    puts "Benchmarking methods from classes:"
    benchmarking_classes.each do |klass|
      puts "* Benchmarking <#{klass.name}>"
      klass.include MethodBenchmarking
      (klass.methods - [Object.methods].flatten).sort.compact.uniq.each do |method_name|
        next unless klass.method_defined?(method_name)
        klass.instance_eval do 
          benchmark_method method_name, tag: 'configured_at_init'
        end
      end
    end
  end
end