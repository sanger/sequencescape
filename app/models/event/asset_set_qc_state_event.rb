# frozen_string_literal: true
class Event::AssetSetQcStateEvent < Event
  class << self
    def create_updated!(asset, reason)
      create!(eventful: asset, family: 'update', content: reason, message: reason)
    end
  end
end
