module Aker
  module Factories
    class Material
      include ActiveModel::Model

      attr_reader :name, :gender, :donor_id, :phenotype, :sample_common_name, :container, :model

      validates_presence_of :name, :gender, :donor_id, :phenotype, :sample_common_name

      validate :check_container

      def self.create(params)
        new(params).create
      end

      def initialize(params)
        @name = params[:_id]
        @gender = params[:gender]
        @donor_id = params[:donor_id]
        @phenotype = params[:phenotype]
        @sample_common_name = params[:common_name]
        @container = Aker::Factories::Container.new(params[:container])
      end

      def create
        return unless valid?
        @model = Sample.create(attributes)
      end

      def attributes
        {
          name: name,
          sample_metadata_attributes: {
            gender: gender,
            donor_id: donor_id,
            phenotype: phenotype,
            sample_common_name: sample_common_name
          },
          container: container.create
        }
      end

      private

      def check_container
        return if container.valid?
        container.errors.each do |key, value|
          errors.add key, value
        end
      end
    end
  end
end
