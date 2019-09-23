# frozen_string_literal: true

module Core::Benchmarking
  def self.registered(app)
    app.helpers self
  end

  def benchmark(_message = nil)
    yield
    # ActiveRecord::Base.benchmark("===== API benchmark (#{message || 'general'}):", Logger::ERROR, &block)
  end
end
