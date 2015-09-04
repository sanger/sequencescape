#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class BroadcastEvent < ActiveRecord::Base

  EVENT_JSON_ROOT = 'event'
  UNKNOWN_USER_IDENTIFIER = 'UNKNOWN'

  include Uuid::Uuidable

  extend BroadcastEvent::SubjectHelpers::SubjectableClassMethods
  extend BroadcastEvent::MetadataHelpers::MetadatableClassMethods
  extend BroadcastEvent::MetadataHelpers::MetadatableClassMethods
  extend BroadcastEvent::RenderHelpers::RenderableClassMethods

  belongs_to :seed, :polymorphic => true
  belongs_to :user
  validates_presence_of :seed
  validates_presence_of :user

  def initialize(*args)
    raise StandardError, 'BroadcastEvents can not be created directly' unless self.class < BroadcastEvent
    super
  end

  # Prefer email, fall back to login if missing
  def user_identifier
    return UNKNOWN_USER_IDENTIFIER if user.nil? # User has probably been deleted
    user.email.blank? ? user.login : user.email
  end

  # Returns an array of all subjects
  def subjects
    self.class.subject_associations.map do |sa|
      sa.for(seed)
    end.flatten
  end

  # Returns a hash of all metadata
  def metadata
    Hash[self.class.metadata_finders.map {|mf| mf.for(seed) } ]
  end

  def json_root
    EVENT_JSON_ROOT
  end

  def event_type
    self.class.event_type
  end

  def self.set_event_type(event_type)
    @event_type = event_type
  end

  def self.event_type
    @event_type
  end


end
