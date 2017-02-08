# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2015 Genome Research Ltd.

module SampleManifest::CoreBehaviour
  # Include in cores which exhibit the default behaviour
  module NoSpecializedValidation
    def validate_specialized_fields(*args); end

    def specialized_fields(*_args); {}; end
  end

  def self.included(base)
    base.class_eval do
      delegate :details, :details_array, :validate_sample_container, :validate_specialized_fields, :specialized_fields, to: :core_behaviour

      attr_accessor :rapid_generation
      alias_method(:rapid_generation?, :rapid_generation)

      def self.supported_asset_type?(asset_type)
        asset_type.nil? || ['1dtube', 'plate', 'multiplexed_library'].include?(asset_type)
      end
    end
  end

  private

  def core_behaviour
    @core_behaviour ||= "::SampleManifest::#{behaviour_module}::#{core_module}".constantize.new(self)
  end

  def behaviour_module
    case asset_type
    when '1dtube'              then 'SampleTubeBehaviour'
    when 'plate'               then 'PlateBehaviour'
    when 'multiplexed_library' then 'MultiplexedLibraryBehaviour'
    else raise StandardError, "Unknown core behaviour (#{asset_type.inspect}) for sample manifest"
    end
  end

  def core_module
    rapid_generation? ? 'RapidCore' : 'Core'
  end
end
