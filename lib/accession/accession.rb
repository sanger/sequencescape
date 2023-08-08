# frozen_string_literal: true
module Accession # rubocop:todo Style/Documentation
  # Handles assigning of accessioning number to a Sequenescape sample.
  # Before accessioning:
  #  check configuration settings, in particular:
  #   configatron.proxy
  #   configatron.accession url, ega.user, ega.password, ena.user, ena.password
  #   configarton.accession_local_key (authorised user uuid)
  # check that Sequenescape sample sample_metadata meets accessioning requirements
  # configatron.accession_samples flag should be set to true to automatically accession a sample after save
  # (app/models/sample.rb)
  #
  # Accessioning steps:
  #  1. Create new Accession::Sample, with tags hash (Accession.configuration.tags) and a Sequencescape sample as
  #     arguments.
  #  2. Checks if a new accession sample is valid (it will check if Sequencescape sample can be accessioned).
  #  3. Create new Accession::Submission, with authorised user and a valid accession sample as arguments.
  #  4. submission.post will send a post request (using Accession::Request) to an outside service (API).
  #   If the request is successful, Accession::Response will be created, it should have an accession number
  #  5. submission.update_accession_number updates Sequenescape sample accession number
  #
  # An example of usage is provided in Sequenescape app/jobs/sample_accessioning_job.rb
  #
  # @see ftp://ftp.sra.ebi.ac.uk/meta/xsd/ Schema definitions
  module Helpers
    def load_file(folder, filename)
      YAML.load_file(Rails.root.join(folder, "#{filename}.yml")).with_indifferent_access
    end
  end

  module Equality # rubocop:todo Style/Documentation
    include Comparable

    def to_a
      attributes.filter_map { |v| instance_variable_get("@#{v}") }
    end

    ##
    # Two objects are comparable if all of their instance variables that are present
    # are comparable.
    def <=>(other)
      return unless other.is_a?(self.class)

      to_a <=> other.to_a
    end
  end

  require_relative 'accession/core_extensions'
  require_relative 'accession/accessionable'
  require_relative 'accession/contact'
  require_relative 'accession/service'
  require_relative 'accession/sample'
  require_relative 'accession/tag'
  require_relative 'accession/tag_list'
  require_relative 'accession/submission'
  require_relative 'accession/request'
  require_relative 'accession/response'
  require_relative 'accession/null_response'
  require_relative 'accession/configuration'

  String.include CoreExtensions::String

  CENTER_NAME = 'SC'
  XML_NAMESPACE = { 'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance' }.freeze

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
