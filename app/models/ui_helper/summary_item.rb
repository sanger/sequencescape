# frozen_string_literal: true
module UiHelper
  class SummaryItem
    attr_accessor :message, :object, :timestamp, :external_link, :external_message

    def initialize(options = {})
      @message = options[:message]
      @object = options[:object]
      @timestamp = options[:timestamp]
      @external_link = options[:external_link]
      @external_message = options[:external_message]
    end
  end
end
