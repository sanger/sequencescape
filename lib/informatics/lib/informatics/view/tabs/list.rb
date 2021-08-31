# frozen_string_literal: true
module Informatics
  module View
    module Tabs
      class List # rubocop:todo Style/Documentation
        attr_accessor :items

        def initialize(_options = {})
          @items = []
        end

        def add_item(options)
          @items.push Informatics::View::Tabs::Item.new(text: options[:text], link: options[:link])
        end
      end
    end
  end
end
