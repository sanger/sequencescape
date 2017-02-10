module Informatics
  module View
    module Menu
      class List
        attr_accessor :items

        def add_item(options = {})
          if !@items
            @items = []
          end
          @items.push Informatics::View::Menu::Item.new(text: options[:text], link: options[:link], method: options[:method], confirm: options[:confirm])
        end
      end
    end
  end
end
