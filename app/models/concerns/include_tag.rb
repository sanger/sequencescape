# frozen_string_literal: true

# Concern to add the include_tag method to samples for accessioning tags
# (not to be confused with aliquot tags)
module IncludeTag
  def include_tag(tag, options = {})
    tags << AccessionedTag.new(tag, options[:as], options[:services], options[:downcase])
  end

  class AccessionedTag
    attr_reader :tag, :name, :downcase

    def initialize(tag, as = nil, services = [], downcase = false)
      @tag = tag
      @name = as || tag
      @services = [services].flatten.compact
      @downcase = downcase
    end

    def for?(service)
      @services.empty? || @services.include?(service)
    end
  end
end
