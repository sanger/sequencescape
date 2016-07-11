module SampleManifestExcel
  class ConditionalFormattingDefault
    include HashAttributes

    set_attributes :type, :style, :options

    def initialize(attributes = {})
      create_attributes(attributes)
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
  end
end