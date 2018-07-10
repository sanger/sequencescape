# frozen_string_literal: true

module SampleManifestExcel
  module SpecialisedField
    ##
    # Base
    module Base
      extend ActiveSupport::Concern

      included do
        include ActiveModel::Model

        define_method :initialize do |attributes = {}|
          super(attributes)
        end
      end

      attr_accessor :value, :sample

      delegate :present?, to: :value, prefix: true

      def update(_attributes = {}); end
    end
  end
end
