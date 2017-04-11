# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

module BroadcastEvent::SubjectHelpers
  class Subject
    attr_reader :target, :role_type

    def initialize(name, target)
      @role_type = name.to_s
      @target = target
    end

    def json_fields
      [:friendly_name, :uuid, :subject_type, :role_type]
    end

    def as_json(*_args)
      Hash[json_fields.map { |f| [f, send(f)] }]
    end

    delegate :friendly_name, :uuid, :subject_type, to: :target
  end

  module SimpleTargetLookup
    def initialize(name, method)
      @name = name
      @method = method
    end

    def target_for(seed, _event)
      seed.send(method)
    end

    def self.included(base)
      base.class_eval { attr_reader :name, :method }
    end
  end

  module BlockTargetLookup
    def initialize(name, &block)
      @name = name
      @block = block
    end

    def target_for(seed, event)
      block.call(seed, event)
    end

    def self.included(base)
      base.class_eval { attr_reader :name, :block }
    end
  end

  module SingleTarget
    def for(seed, event)
      Subject.new(name, target_for(seed, event))
    end
  end

  module MultiTarget
    def for(seed, event)
      target_for(seed, event).map { |t| Subject.new(name, t) }
    end
  end

  class SeedSubjectAssociation
    attr_reader :name

    def initialize(name)
      @name = name
    end

    def for(seed, _event)
      Subject.new(name, seed)
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

  module SubjectableClassMethods
    # The class expected to seed the messenger
    def seed_class(seed_class)
      @seed_class = seed_class
    end

    # The role type that will identify the seed (if applicable)
    def seed_subject(role_type)
      subject_associations << SeedSubjectAssociation.new(role_type)
    end

    # Defines a new subject, specifies the role type and either a method on the seed that will return
    # the subject, or a block that gets passed the seed, and will return the subject.
    def has_subject(role_type, method = nil, &block)
      return subject_associations << SimpleSingleSubjectAssociation.new(role_type, method) unless method.nil?
      return subject_associations << BlockSingleSubjectAssociation.new(role_type, &block) unless block.nil?
      raise StandardError, "No block or method defined for #{role_type} on #{name}"
    end

    # Used when you explicitly expect to receive more than one subject
    def has_subjects(role_type, method = nil, &block)
      return subject_associations << SimpleManySubjectAssociation.new(role_type, method) unless method.nil?
      return subject_associations << BlockManySubjectAssociation.new(role_type, &block) unless block.nil?
      raise StandardError, "No block or method defined for #{role_type} on #{name}"
    end

    def subject_associations
      @subject_associations ||= []
    end
  end

  module Subjectable
    def self.included(base)
      base.class.extend SubjectableClassMethods
    end
  end
end
