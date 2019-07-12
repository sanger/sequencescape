# frozen_string_literal: true

module SequencescapeExcel
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

      # attr_writer :sample
      attr_accessor :value, :sample_manifest_asset

      def sample
        @sample || sample_manifest_asset.sample
      end

      delegate :present?, to: :value, prefix: true
      delegate :asset, to: :sample_manifest_asset

      def update(_attributes = {}); end
    end
  end
end
