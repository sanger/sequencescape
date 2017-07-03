module Aker
  module Factories
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
        @model = Aker::Container.find_or_create_by(barcode: barcode) do |c|
          c.address = address
        end
      end
    end
  end
end
