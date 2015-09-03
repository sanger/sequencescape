#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
module BroadcastEvent::SubjectHelpers
   class Subject

    attr_reader :target, :role_type

    def initialize(name,target)
      @role_type = name.to_s
      @target = target
    end

    delegate :friendly_name, :uuid, :subject_type, :to => :target
  end

  module SimpleTargetLookup
    def initialize(name,method)
      @name = name
      @method = method
    end

    def target_for(seed)
      seed.send(method)
    end

    def self.included(base)
      base.class_eval { attr_reader :name, :method }
    end
  end

  module BlockTargetLookup
    def initialize(name,&block)
      @name = name
      @block = block
    end

    def target_for(seed)
      block.call(seed)
    end

    def self.included(base)
      base.class_eval { attr_reader :name, :block }
    end
  end

  module SingleTarget
    def for(seed)
      Subject.new(name,target_for(seed))
    end
  end

  module MultiTarget
    def for(seed)
      target_for(seed).map {|t| Subject.new(name,t) }
    end
  end

  class SeedSubjectAssociation

    attr_reader :name

    def initialize(name)
      @name = name
    end
    def for(seed)
      Subject.new(name,seed)
    end
  end

  class SimpleSingleSubjectAssociation
    include SimpleTargetLookup
    include SingleTarget
  end

  class SimpleManySubjectAssociation
    include SimpleTargetLookup
    include MultiTarget
  end

  class BlockSingleSubjectAssociation
    include BlockTargetLookup
    include SingleTarget
  end

  class BlockManySubjectAssociation
    include BlockTargetLookup
    include MultiTarget
  end
end
