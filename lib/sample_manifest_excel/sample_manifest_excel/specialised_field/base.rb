module SampleManifestExcel
  module SpecialisedField
    module Base
      extend ActiveSupport::Concern

      included do
        include ActiveModel::Model

        define_method :initialize do |_attributes = {}|
          super
        end
      end

      attr_accessor :value, :sample

      def update(_attributes = {})
      end
    end
  end
end