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

        @model =
          Aker::Container.find_or_create_by(barcode: barcode, address: address) do |m|
            @labware = find_or_create_asset_by_aker_barcode!

            # Connects Aker container with asset. If is a plate, connects with the well, if is a tube, directly with
            # the tube
            m.update(asset: a_well? ? @labware.wells.located_at(address_for_ss).first : @labware)
          end
      end

      def as_json(_options = {})
        model.as_json
      end

      def a_well?
        !Aker::Container.tube_address?(address)
      end

      private

      def create_asset!
        a_well? ? PlatePurpose.stock_plate_purpose.create! : Tube::Purpose.standard_sample_tube.create!
      end

      def find_or_create_asset_by_aker_barcode!
        labware = Labware.find_from_barcode(barcode)
        unless labware
          labware = create_asset!
          labware.aker_barcode = barcode
          labware.save!
        end
        labware
      end

      def address_for_ss
        address.delete(':')
      end
    end
  end
end
