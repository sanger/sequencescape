##
# Creates a Sample Manifest Excel spreadsheet from a Sample Manifest object
module SampleManifestExcel
  module AttributeHelpers
    extend ActiveSupport::Concern
    include ActiveModel::Model
    include ActiveRecord::AttributeAssignment
    include Comparable

    module ClassMethods
      def set_attributes(*attributes)
        options = attributes.extract_options!

        attr_accessor(*attributes)

        define_method :attributes do
          attributes
        end

        define_method :default_attributes do
          options[:defaults] || {}
        end
      end
    end

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

  require_relative 'sample_manifest_excel/core_extensions'
  require_relative 'sample_manifest_excel/attributes'
  require_relative 'sample_manifest_excel/cell'
  require_relative 'sample_manifest_excel/list'
  require_relative 'sample_manifest_excel/conditional_formatting_default'
  require_relative 'sample_manifest_excel/conditional_formatting_default_list'
  require_relative 'sample_manifest_excel/manifest_type_list'
  require_relative 'sample_manifest_excel/specialised_field'
  require_relative 'sample_manifest_excel/multiplexed_library_tube_field'
  require_relative 'sample_manifest_excel/sample_field'
  require_relative 'sample_manifest_excel/specialised_field_list'
  require_relative 'sample_manifest_excel/validation'
  require_relative 'sample_manifest_excel/column'
  require_relative 'sample_manifest_excel/column_list'
  require_relative 'sample_manifest_excel/conditional_formatting'
  require_relative 'sample_manifest_excel/conditional_formatting_list'
  require_relative 'sample_manifest_excel/formula'
  require_relative 'sample_manifest_excel/range'
  require_relative 'sample_manifest_excel/range_list'
  require_relative 'sample_manifest_excel/worksheet'
  require_relative 'sample_manifest_excel/download'
  require_relative 'sample_manifest_excel/upload'

  Axlsx::Worksheet.send(:include, CoreExtensions::AxlsxWorksheet)

  module Helpers
    def load_file(folder, filename)
      YAML::load_file(File.join(Rails.root, folder, "#{filename}.yml")).with_indifferent_access
    end
  end

  mattr_accessor :first_row
  self.first_row = 10

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
