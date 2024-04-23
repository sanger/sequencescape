# frozen_string_literal: true
module Informatics
  module View
    module Menu
      class List
        attr_accessor :items

        def add_item(options = {})
          @items ||= []
          @items.push Informatics::View::Menu::Item.new(
                        text: options[:text],
                        link: options[:link],
                        method: options[:method],
                        confirm: options[:confirm]
                      )
        end
      end
    end
  end
end
