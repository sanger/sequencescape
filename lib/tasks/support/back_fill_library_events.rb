# Added to backfill data for https://github.com/sanger/unified_warehouse/issues/119
# This is a one time event, so can be removed once run.
class BackFillLibraryEvents
  # All Limber stock plates by name
  LIMBER_STOCK_PLATES = [
    'PF Cherrypicked',
    'LBB Cherrypick',
    'LBC Stock',
    'LDS Stock',
    'LDS Cherrypick',
    'GBS Stock',
    'GBS-96 Stock',
    'GnT Stock',
    'LHR-384 RT',
    'LHR RT',
    'LBR Cherrypick',
    'scRNA Stock',
    'scRNA-384 Stock',
    'LB Cherrypick'
  ].freeze

  # A struct to hold our event information
  OrderState = Struct.new(:order_id, :occurred_at, :labware, :user_id, :skip)

  # Takes an individual plate, and extracts the earliest state change for each order
  class ParentProcessor
    attr_reader :parent, :order_store, :deploy_date

    def initialize(parent, deploy_date)
      @parent = parent
      @deploy_date = deploy_date
      @order_store = new_array_store
    end

    # Extract the events from the plate, and then build them
    def process
      Rails.logger.info "===#{parent.id} Children:#{parent.children.length}"
      extract_events
      build_events
    end

    private

    def new_array_store
      Hash.new { |h, i| h[i] = [] }
    end

    # Stores all orders associated with a submission on the parent plate.
    # Useful for older plates, where the aliquots don't link directly to their requests.
    # Instead we extract the submissions via the transfer requests, and then use this to map it back to the orders.
    # We extract this information lazily as we only need it for a subset of plates, and eager loading was getting very
    # inefficient
    def submission_store
      @submission_store ||= new_array_store.tap do |submission_store|
        parent.well_requests_as_source.distinct.pluck(:submission_id, :order_id).each do |submission_id, order_id|
          submission_store[submission_id] << order_id
        end
      end
    end

    # Determines if we need to create an event
    # PlatePurpose::Initial was correctly handling event creation, and mainly affects PF Shear plates
    # For other plates, we assume no events exist for older plates, and only bother checking those
    # that occurred recently. This is because checking event is pretty slow.
    # (No indexes, as they typically aren't needed)
    def existing_event?(labware, state_change)
      return true if labware.purpose.is_a?(PlatePurpose::Initial)

      if state_change.created_at < deploy_date
        false # Our event pre-dates the fixes
      else
        BroadcastEvent::LibraryStart.exists?(seed: labware)
      end
    end

    # Extract all state changes for each order
    def extract_events
      # We may have multiple children. In some cases these may reflect different submissions,
      # in others plates created in error and never used. We collect all non fail/cancel
      # state changes associated with each order, and the piece of labware they were associated with.
      # Later we can identify the earliest action for each order, which maps to the point at which the
      # library was 'started'
      parent.children.each do |child|
        # Extract the order ids associated with the plates.
        # First we try going via the requests on aliquots, but earlier plates
        # don't have this information available, so we set up a fall-back.
        order_ids = child.in_progress_requests.reject(&:pending?).map(&:order_id).presence ||
                    child.in_progress_submissions.ids.flat_map { |sub_id| submission_store[sub_id] }

        order_ids.uniq.each do |order_id|
          child.state_changes.each do |sc|
            next if %w[failed cancelled].include? sc.target_state

            skip = existing_event?(child, sc)
            order_store[order_id] << OrderState.new(order_id, sc.created_at, child, sc.user_id, skip)
          end
        end
      end
    end

    # Now build the events for each plate
    def build_events
      order_store.each_value do |order_states|
        # If any of the states have the skip flag sets, that indicates that we've
        # already recorded a LibraryStart event for this order, so can move in
        if order_states.any?(&:skip)
          Rails.logger.info "Already recorded: #{order_states.first.order_id}"
          next
        end

        # Find the earliest state change associated with each order
        earliest = order_states.min(&:occurred_at)
        # Log it
        Rails.logger.info earliest
        # Create the event
        BroadcastEvent::LibraryStart.create!(
          seed: earliest.labware,
          created_at: earliest.occurred_at,
          user_id: earliest.user_id,
          properties: { order_id: earliest.order_id }
        )
      end
    end
  end

  attr_reader :deploy_date

  def initialize(deploy_date)
    @deploy_date = deploy_date
  end

  # Run the back-population for all plates
  def run
    Rails.logger.info 'Running'
    each_parent { |parent| ParentProcessor.new(parent, deploy_date).process }
  end

  private

  def stock_purposes
    Purpose.where(name: LIMBER_STOCK_PLATES)
  end

  def each_parent
    Plate.where(plate_purpose_id: stock_purposes)
         .includes(children: %i[in_progress_requests state_changes purpose in_progress_submissions])
         .find_each { |parent| yield parent }
  end
end
