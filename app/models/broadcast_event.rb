# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

class BroadcastEvent < ApplicationRecord
  EVENT_JSON_ROOT = 'event'
  UNKNOWN_USER_IDENTIFIER = 'UNKNOWN'

  include Uuid::Uuidable

  extend BroadcastEvent::SubjectHelpers::SubjectableClassMethods
  extend BroadcastEvent::MetadataHelpers::MetadatableClassMethods
  extend BroadcastEvent::RenderHelpers::RenderableClassMethods

  belongs_to :seed, polymorphic: true
  belongs_to :user
  validates_presence_of :seed

  serialize :properties
  self.inheritance_column = 'sti_type'

  broadcast_via_warren

  def initialize(*args)
    raise StandardError, 'BroadcastEvents can not be created directly' unless self.class < BroadcastEvent
    super
  end

  # Prefer email, fall back to login if missing
  def user_identifier
    return UNKNOWN_USER_IDENTIFIER if user.nil? # User has probably been deleted
    user.email.presence || user.login
  end

  # Returns an array of all subjects
  def subjects
    self.class.subject_associations.map do |sa|
      sa.for(seed, self)
    end.flatten
  end

  # Returns a hash of all metadata
  def metadata
    Hash[self.class.metadata_finders.map { |mf| mf.for(seed, self) }]
  end

  def routing_key
    "#{Rails.env}.event.#{event_type}.#{id}"
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
