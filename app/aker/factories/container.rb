module Aker
  module Factories
    ##
    # A Container is something that stores a sample.
    # At this stage it is not defined.
    # Must have a barcode
    class Container
      include ActiveModel::Model

      attr_reader :barcode, :address, :model

      validates_presence_of :barcode

      def self.create(params)
        new(params).create
      end

      def initialize(params)
        params ||= {}
        @barcode = params[:barcode]
        @address = params[:address]
      end

      def create
        return unless valid?
        @model = Aker::Container.find_or_create_by(barcode: barcode, address: address)
      end

      def as_json(_options = {})
        model.as_json
      end
    end
  end
end
