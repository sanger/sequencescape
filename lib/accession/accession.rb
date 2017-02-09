module Accession
  module Helpers
    def load_file(folder, filename)
      YAML::load_file(File.join(Rails.root, folder, "#{filename}.yml")).with_indifferent_access
    end
  end

  module Equality
    include Comparable

    def to_a
      attributes.collect { |v| instance_variable_get("@#{v}") }.compact
    end

    ##
    # Two objects are comparable if all of their instance variables that are present
    # are comparable.
    def <=>(other)
      return unless other.is_a?(self.class)
      to_a <=> other.to_a
    end
  end

  require_relative "accession/core_extensions"
  require_relative "accession/contact"
  require_relative "accession/service"
  require_relative "accession/sample"
  require_relative "accession/tag"
  require_relative "accession/tag_list"
  require_relative "accession/submission"
  require_relative "accession/request"
  require_relative "accession/response"
  require_relative "accession/null_response"
  require_relative "accession/configuration"

  String.send(:include, CoreExtensions::String)

  CENTER_NAME = "SC"
  XML_NAMESPACE = { 'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance' }

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
