module SampleManifestExcel
  class ConditionalFormattingDefault
    include Helpers::Attributes

    set_attributes :type, :style, :options

    def initialize(attributes = {})
      super
    end

    def type=(type)
      @type = type.to_sym
    end

    def expression?
      options[:type] == :expression
    end

    def combine(other = nil)
      (other || {}).merge(style: style, options: options).with_indifferent_access.tap do |cf|
        if expression?
          cf[:formula] ||= {}
          cf[:formula].merge!(type: type)
        end
      end
    end

    def inspect
      "<#{self.class}: @type=#{type}, @style=#{style}, @options=#{options}>"
    end
  end
end
