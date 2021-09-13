# frozen_string_literal: true
module Informatics
  module View
    module Tabs
      class Item # rubocop:todo Style/Documentation
        attr_accessor :text, :link

        def initialize(options = {})
          @text = options[:text]
          @link = options[:link]
        end
      end
    end
  end
end
