module Informatics
  module View
    module Menu
      class Item

        attr_accessor :text, :link, :confirm, :method

        def initialize(options = {})
          @text = options[:text]
          @link = options[:link]
          @confirm = options[:confirm]
          @method = options[:method]
        end

      end
    end
  end
end
