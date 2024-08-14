# frozen_string_literal: true

module Api
  module V2
    module Transfers
      # Provides a JSON API representation of a Transfer.
      # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
      class TransferResource < BaseResource
        # @!attribute [r]
        #   @return [String] the UUID of the transfer.
        attribute :uuid, readonly: true

        # @!attribute [rw]
        #   @return [String] the UUID of the source labware.
        #     The type of the labware varies by the type of transfer.
        attribute :source_uuid

        def source_uuid
          @model.source.uuid
        end

        def source_uuid=(uuid)
          @model.source = Plate.find_by(uuid: uuid)
        end

        # @!attribute [rw]
        #   @return [String, void] the UUID of the destination labware.
        attribute :destination_uuid

        def destination_uuid
          @model.destination&.uuid
        end

        def destination_uuid=(uuid)
          @model.destination = Labware.find_by(uuid: uuid) if destination_uuid
        end

        # @!attribute [rw]
        #   @return [String] the UUID of the user who requested the transfer.
        attribute :user_uuid

        def user_uuid
          @model.user.uuid
        end

        def user_uuid=(uuid)
          @model.user = User.find_by(uuid: uuid)
        end

        # @!attribute [rw]
        #   @return [Hash] a hash of the transfers made.
        attribute :transfers, delegate: :transfers_hash

        # @!attribute [w]
        #   @return [String] the UUID of a transfer template to create a transfer from.
        attribute :transfer_template_uuid

        def fetchable_fields
          # Do not fetch the transfer template.
          # It is only submitted when creating a new transfer and not stored.
          super - %i[transfer_template_uuid]
        end
      end

      class BetweenPlateResource < TransferResource
        filter :sti_type, default: 'Transfer::BetweenPlates'
      end

      class BetweenPlateAndTubeResource < TransferResource
        filter :sti_type, default: 'Transfer::BetweenPlateAndTube'
      end

      class BetweenPlatesBySubmissionResource < TransferResource
        filter :sti_type, default: 'Transfer::BetweenPlatesBySubmission'
      end

      class BetweenSpecificTubeResource < TransferResource
        filter :sti_type, default: 'Transfer::BetweenSpecificTubes'
      end

      class BetweenTubesBySubmissionResource < TransferResource
        filter :sti_type, default: 'Transfer::BetweenTubesBySubmission'
      end

      class FromPlateToSpecificTubesByPoolResource < TransferResource
        filter :sti_type, default: 'Transfer::FromPlateToSpecificTubesByPool'
      end

      class FromPlateToSpecificTubeResource < TransferResource
        filter :sti_type, default: 'Transfer::FromPlateToSpecificTube'
      end

      class FromPlateToTubeByMultiplexResource < TransferResource
        filter :sti_type, default: 'Transfer::FromPlateToTubeByMultiplex'
      end

      class FromPlateToTubeBySubmissionResource < TransferResource
        filter :sti_type, default: 'Transfer::FromPlateToTubeBySubmission'
      end

      class FromPlateToTubeResource < TransferResource
        filter :sti_type, default: 'Transfer::FromPlateToTube'
      end
    end
  end
end
