module UiHelper
  class SummaryItem
    attr_accessor :message
    attr_accessor :object
    attr_accessor :timestamp

    attr_accessor :external_link
    attr_accessor :external_message

    def initialize(options = {})
      @message = options[:message]
      @object  = options[:object]
      @timestamp = options[:timestamp]
      @external_link = options[:external_link]
      @external_message = options[:external_message]
    end
  end
end
