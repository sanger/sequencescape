#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class BroadcastEvent < ActiveRecord::Base


  belongs_to :seed, :polymorphic => true
  validates_presence_of :seed

  def initialize(*args)
    raise StandardError, 'BroadcastEvents can not be created directly' unless self.class < BroadcastEvent
    super
  end

  # Returns an array of all subjects
  def subjects
    self.class.subject_associations.map do |sa|
      sa.for(seed)
    end.flatten
  end

  module ClassMethods
    # The class expected to seed the messenger
    def seed_class(seed_class)
      @seed_class = seed_class
    end

    # The role type that will identify the seed (if applicable)
    def seed_subject(role_type)
      subject_associations << Helpers::SeedSubjectAssociation.new(role_type)
    end

    # Defines a new subject, specifies the role type and either a method on the seed that will return
    # the subject, or a block that gets passed the seed, and will return the subject.
    def has_subject(role_type,method=nil,&block)
      return subject_associations << SubjectHelpers::SimpleSingleSubjectAssociation.new(role_type,method) unless method.nil?
      return subject_associations << SubjectHelpers::BlockSingleSubjectAssociation.new(role_type,&block) unless block.nil?
      raise StandardError, "No block or method defined for #{role_type} on #{name}"
    end

    # Used when you explicitly expect to receive more than one subject
    def has_subjects(role_type,method=nil,&block)
      return subject_associations << SubjectHelpers::SimpleManySubjectAssociation.new(role_type,method) unless method.nil?
      return subject_associations << SubjectHelpers::BlockManySubjectAssociation.new(role_type,&block) unless block.nil?
      raise StandardError, "No block or method defined for #{role_type} on #{name}"
    end

    def subject_associations
      @subject_associations ||= []
    end
  end
  extend ClassMethods

end
