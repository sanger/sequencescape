module Core::Benchmarking
  def self.registered(app)
    app.helpers self
  end

  def benchmark(message = nil, &block)
    yield
    #ActiveRecord::Base.benchmark("===== API benchmark (#{message || 'general'}):", Logger::ERROR, &block)
  end
end
