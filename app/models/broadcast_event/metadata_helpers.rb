# frozen_string_literal: true
module BroadcastEvent::MetadataHelpers
  class SimpleMetadataFinder # rubocop:todo Style/Documentation
    attr_reader :name, :method

    def initialize(name, method)
      @name = name.to_s
      @method = method
    end

    def for(seed, _event)
      [name, seed.send(method)]
    end
  end

  class BlockMetadataFinder # rubocop:todo Style/Documentation
    attr_reader :name, :block

    def initialize(name, &block)
      @name = name.to_s
      @block = block
    end

    def for(seed, event)
      [name, block.call(seed, event)]
    end
  end

  module MetadatableClassMethods # rubocop:todo Style/Documentation
    def has_metadata(key, method = nil, &block)
      return metadata_finders << SimpleMetadataFinder.new(key, method) unless method.nil?
      return metadata_finders << BlockMetadataFinder.new(key, &block) unless block.nil?

      raise StandardError, "No block or method defined for #{key} on #{name}"
    end

    def metadata_finders
      @metadata_finders ||= []
    end
  end
end
