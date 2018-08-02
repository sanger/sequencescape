module Aker
  module Factories
    ##
    # An Aker material which in this case is a Samples.
    # Must have a Container
    # Must have minimal data which relates to SampleMetadata and includes:
    #  * name (Aker uuid)
    #  * gender
    # Optional data:
    #  * donor_id
    #  * phenotype
    #  * sample_common_name (Aker: common name)
    class Material
      include ActiveModel::Model
      attr_accessor :container, :study
      attr_reader :sample

      # validates_presence_of :uuid, :gender

      validate :check_container, :check_supplier_name, :check_uuid, :check_gender

      def initialize(params, container, study)
        @params = params
        @container = container
        @study = study
      end

      def create_sample!
        sanger_sample_id = SangerSampleId.generate_sanger_sample_id!(study.abbreviation, sanger_sample_id)
        @sample = Sample.create!(name: sanger_sample_id, sanger_sample_id: sanger_sample_id)
        @sample.create_uuid_object!(external_id: @params[:_id])
      end

      ##
      # Persists the material including the associated container
      def create
        return unless valid?

        container_model = container.create
        @sample = Sample.include_uuid.find_by(uuids: { external_id: @params[:_id] })
        create_sample! unless @sample

        container_model.put_sample_in_container(sample, study)
        put_study_in_sample(study)

        Aker::Material.new(@sample).update!(@params)

        @sample
      end

      def put_study_in_sample(study)
        sample.studies << study if study && !sample.studies.include?(study)
      end

      def as_json
        Aker::Material.new(sample).attributes
      end

      private

      def check_gender
        errors.add(:gender, 'No gender defined') unless @params[:gender]
      end

      def check_container
        if container.nil?
          errors.add(:container, 'This material has no container')
          return
        end
        return if container.valid?
        container.errors.each do |key, value|
          errors.add key, value
        end
      end

      def check_supplier_name
        errors.add(:name, 'No supplier name defined') unless @params[:supplier_name]
      end

      def check_uuid
        errors.add(:uuid, 'No uuid defined') unless @params[:_id]
      end
    end
  end
end
