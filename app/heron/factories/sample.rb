module Heron
  module Factories
    #
    # Factory class to generate sample tubes inside a Heron rack
    class Sample
      include ActiveModel::Model
      attr_accessor :sample

      validates_presence_of :study

      validate :check_no_other_params_when_uuid

      def initialize(params)
        @params = params
      end

      def check_no_other_params_when_uuid
        return unless @params[:sample_uuid]

        errors(:base, 'No other params can be added when sample uuid specified') unless (@params.keys - %i[sample_uuid study study_uuid]).empty?
      end

      ##
      # Persists the material including the associated container
      def create
        return unless valid?

        @sample = create_sample!
      end

      def study
        @study ||= @params[:study] || Study.with_uuid(@params[:study_uuid]).first
      end

      def create_sanger_sample_id!
        SangerSampleId.generate_sanger_sample_id!(study.abbreviation)
      end

      def sanger_sample_id
        @sanger_sample_id ||= @params[:sanger_sample_id] || create_sanger_sample_id!
      end

      def create_sample!
        return ::Sample.with_uuid(@params[:sample_uuid]).first if @params[:sample_uuid]

        ::Sample.create!(params_for_sample_creation) do |sample|
          sample.sample_metadata.update!(params_for_sample_metadata_table)
          sample.studies << study
        end
      end

      def params_for_sample_creation
        {
          name: sanger_sample_id,
          sanger_sample_id: sanger_sample_id
        }.merge(params_for_sample_table)
      end

      def params_for_sample_table
        @params.select { |k, _v| ::Sample.column_names.include?(k.to_s) }
      end

      def params_for_sample_metadata_table
        @params.select { |k, _v| ::Sample::Metadata.column_names.include?(k.to_s) }
      end
    end
  end
end
