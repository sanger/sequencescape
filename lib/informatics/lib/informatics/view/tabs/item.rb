module Informatics
  module View
    module Tabs

      class Item

        attr_accessor :text, :link

        def initialize(options = {})
          @text = options[:text]
          @link = options[:link]
        end

      end

    end
  end
end