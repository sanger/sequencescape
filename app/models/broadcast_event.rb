# frozen_string_literal: true
# @see https://github.com/sanger/event_warehouse Event Warehouse
# Abstract class used to generate events; use subclass to specify how your particular event is generated.
class BroadcastEvent < ApplicationRecord
  EVENT_JSON_ROOT = 'event'
  UNKNOWN_USER_IDENTIFIER = 'UNKNOWN'

  include Uuid::Uuidable

  extend BroadcastEvent::SubjectHelpers::SubjectableClassMethods
  extend BroadcastEvent::MetadataHelpers::MetadatableClassMethods
  extend BroadcastEvent::RenderHelpers::RenderableClassMethods

  belongs_to :seed, polymorphic: true
  belongs_to :user
  validates :seed, presence: true

  # Recommended way of preventing the base class from being instantiated
  # https://api.rubyonrails.org/classes/ActiveRecord/Inheritance/ClassMethods.html
  validates :sti_type, presence: true

  serialize :properties, coder: YAML
  self.inheritance_column = 'sti_type'

  broadcast_with_warren

  # Prefer email, fall back to login if missing
  def user_identifier
    return UNKNOWN_USER_IDENTIFIER if user.nil? # User has probably been deleted

    user.email.presence || user.login
  end

  # Returns an array of all subjects
  def subjects
    self.class.subject_associations.flat_map { |sa| sa.for(seed, self) }.select(&:broadcastable?)
  end

  # Returns a hash of all metadata
  def metadata
    self.class.metadata_finders.to_h { |mf| mf.for(seed, self) }
  end

  # Routing key generated for the broadcasted event.
  # @return [String] Routing key. eg. event.library_created.123
  def routing_key
    "event.#{event_type}.#{id}"
  end

  # @return [String] the root of the generated json object. 'event'
  def json_root
    EVENT_JSON_ROOT
  end

  # Override in subclasses if you want dynamic event types
  # @return [String] The value of the event_type key in the generated message
  def event_type
    self.class.event_type
  end

  #
  # Use in subclasses to specify a fixed event type
  # @param event_type [String] The event type to use for this subclass
  #
  # @return [String] The event type
  def self.set_event_type(event_type)
    @event_type = event_type
  end

  # @return [String] The value of the event_type key in the generated message
  class << self
    attr_reader :event_type
  end
end
