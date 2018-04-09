# frozen_string_literal: true

module Api
  module V2
    # AssetResource
    class AssetResource < JSONAPI::Resource
      attributes :uuid
    end
  end
end
