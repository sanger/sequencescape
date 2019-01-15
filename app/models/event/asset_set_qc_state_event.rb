class Event::AssetSetQcStateEvent < Event
  class << self
    def self.constructor_for_event_type(type)
      define_method(:"create_#{ type }!") do |asset, reason|
        create!(
          eventful: asset,
          family: 'update',
          content: reason,
          message: reason
        )
      end
    end

    constructor_for_event_type('passed')
    constructor_for_event_type('failed')
    constructor_for_event_type('updated')
  end
end
