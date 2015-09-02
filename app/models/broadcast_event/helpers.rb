module BroadcastEvent::Helpers
   class Subject

    attr_reader :target, :role_type

    def initialize(name,target)
      @role_type = name.to_s
      @target = target
    end

    delegate :friendly_name, :uuid, :subject_type, :to => :target
  end

  module SimpleTargetLookup
    def target_for(seed)
      seed.send(method)
    end
  end

  module BlockTargetLookup
    def target_for(seed)
      block.call(seed)
    end
  end

  class SimpleSingleSubjectAssociation
    include SimpleTargetLookup

    attr_reader :name, :method

    def initialize(name,method)
      @name = name
      @method = method
    end

    def for(seed)
      Subject.new(name,target_for(seed))
    end
  end

  class SimpleManySubjectAssociation
    include SimpleTargetLookup

    attr_reader :name, :method

    def initialize(name,method)
      @name = name
      @method = method
    end

    def for(seed)
      target = target_for(seed)

      target.map {|t| Subject.new(name,t) }
    end
  end

  class BlockSingleSubjectAssociation
    include BlockTargetLookup
    attr_reader :name, :block

    def initialize(name,&block)
      @name = name
      @block = block
    end

    def for(seed)
      Subject.new(name,target_for(seed))
    end
  end

  class BlockManySubjectAssociation
    include BlockTargetLookup
    attr_reader :name, :block

    def initialize(name,&block)
      @name = name
      @block = block
    end

    def for(seed)
      target_for(seed).map do |t|
        Subject.new(name,t)
      end
    end
  end
end
