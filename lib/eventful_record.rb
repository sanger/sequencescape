# frozen_string_literal: true

# EventfulRecord provides dynamically generated code for managing event associations.
#
# This module adds convenience methods for declaring event-related associations
# on models, including standard events, lab events, and single events filtered by family.
#
# Usage:
#   include EventfulRecord
#   has_many_events
#   has_many_lab_events
#   has_one_event_with_family(:family_name)
module EventfulRecord
  # Defines a has_many :events association with ordering and custom event constructor support.
  def has_many_events(&block)
    has_many(:events, -> { order(created_at: :asc, id: :asc) }, as: :eventful, dependent: :destroy) do
      # Dynamically defines a method for constructing, naming, and adding events of a given class.
      def self.event_constructor(model_event_name, event_class, event_class_method)
        define_method(model_event_name) do |*args|
          event = event_class.public_send(event_class_method, proxy_association.owner, *args)
          self << event if event.eventful.blank?
          event
        end
      end

      class_eval(&block) if block.present?
    end
  end

  # Defines a has_many :lab_events association with ordering.
  def has_many_lab_events(&)
    has_many(:lab_events, -> { order(created_at: :asc, id: :asc) }, as: :eventful, dependent: :destroy, &)
  end

  # Defines a has_one association for a single event filtered by family.
  def has_one_event_with_family(event_family, &)
    has_one(
      :"#{event_family}_event",
      lambda { order(id: :desc).where(family: event_family) },
      class_name: 'Event',
      as: :eventful,
      &
    )
  end
end
