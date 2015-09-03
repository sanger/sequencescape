#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
module BroadcastEvent::MetadataHelpers

  class SimpleMetadataFinder
    attr_reader :name, :method
    def initialize(name,method)
      @name = name.to_s
      @method = method
    end
    def for(seed)
      [name,seed.send(method)]
    end
  end

  class BlockMetadataFinder
    attr_reader :name, :block
    def initialize(name,&block)
      @name = name.to_s
      @block = block
    end
    def for(seed)
      [name,block.call(seed)]
    end
  end

  module MetadatableClassMethods
    def has_metadata(key,method=nil,&block)
      return metadata_finders << SimpleMetadataFinder.new(key,method) unless method.nil?
      return metadata_finders <<  BlockMetadataFinder.new(key,&block) unless block.nil?
      raise StandardError, "No block or method defined for #{key} on #{name}"
    end

    def metadata_finders
      @metadata_finders ||= []
    end

  end
end
