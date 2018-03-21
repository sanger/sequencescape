# module to create and populate billing BIF file (billing report)
module Billing
  def self.table_name_prefix
    'billing_'
  end

  class << self
    attr_writer :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  def self.reset!
    @configuration = Configuration.new
  end
end
