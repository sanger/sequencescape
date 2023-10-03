# frozen_string_literal: true
module EventfulRecord
  def has_many_events(&block) # rubocop:todo Metrics/MethodLength
    has_many(:events, -> { order(created_at: :asc, id: :asc) }, as: :eventful, dependent: :destroy) do
      def self.event_constructor(name, event_class, event_class_method)
        line = __LINE__ + 1

        # rubocop:todo Layout/LineLength
        class_eval(
          "
          def #{name}(*args)
            #{event_class.name}.#{event_class_method}(self.proxy_association.owner, *args).tap { |event| self << event unless event.eventful.present? }
          end
        ",
          __FILE__,
          line
        )
        # rubocop:enable Layout/LineLength
      end

      class_eval(&block) if block.present?
    end
  end

  def has_many_lab_events(&block)
    has_many(:lab_events, -> { order(created_at: :asc, id: :asc) }, as: :eventful, dependent: :destroy, &block)
  end

  def has_one_event_with_family(event_family, &block)
    has_one(
      :"#{event_family}_event",
      lambda { order(id: :desc).where(family: event_family) },
      class_name: 'Event',
      as: :eventful,
      &block
    )
  end
end
