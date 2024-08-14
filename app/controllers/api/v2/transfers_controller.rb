# frozen_string_literal: true

module Api
  module V2
    module Transfers
      # Provides a JSON API controller for Transfers.
      # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation.
      class TransfersController < JSONAPI::ResourceController
        # By default JSONAPI::ResourceController provides most of the standard
        # behaviour, and in many cases this file may be left empty.
      end

      class BetweenPlatesController < JSONAPI::ResourceController
      end

      class BetweenPlateAndTubesController < JSONAPI::ResourceController
      end

      class BetweenPlatesBySubmissionsController < JSONAPI::ResourceController
      end

      class BetweenSpecificTubesController < JSONAPI::ResourceController
      end

      class BetweenTubesBySubmissionsController < JSONAPI::ResourceController
      end

      class FromPlateToSpecificTubesByPoolsController < JSONAPI::ResourceController
      end

      class FromPlateToSpecificTubesController < JSONAPI::ResourceController
      end

      class FromPlateToTubeByMultiplexController < JSONAPI::ResourceController
      end

      class FromPlateToTubeBySubmissionsController < JSONAPI::ResourceController
      end

      class FromPlateToTubesController < JSONAPI::ResourceController
      end
    end
  end
end
