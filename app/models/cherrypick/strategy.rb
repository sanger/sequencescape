class Cherrypick::Strategy
  PickFailureError = Class.new(StandardError)

  # This is the default cherrypicking strategy, that blindly picks the wells in the order that the requests
  # are given.  It will break a pool apart so that it can cross plates, hence this should not be used for
  # plate types that do not permit cross plate pools.
  class Default < Cherrypick::Strategy
    def choose_next_plex_from(requests, current_plate)
      first_request = requests.first
      requests_for_first_plex = requests.select do |r|
        r.submission_id == first_request.submission_id
      end.slice(0, current_plate.available)
      [ requests_for_first_plex, requests - requests_for_first_plex ]
    end
  end

  # This cherrypicking strategy attempts to order the wells in such a fashion as to optimally pack the wells
  # on a plate.  It does not break pools apart, so pools will never be picked that overflow a given plate.
  class Optimum < Cherrypick::Strategy
    def choose_next_plex_from(requests, current_plate)
      # Determine the candidate plexes from the current requests.  These plexes should not overflow the size
      # of the plate with are building, and they should optimally fill the dimension of the plate, leaving
      # no need for empty space if they are larger than the dimension
      candidate_plexes = requests.group_by(&:submission_id).select do |_, plex|
        (plex.size + current_plate.used) <= current_plate.size
      end.select do |_, plex|
        if current_plate.overlap.zero?
          true
        else
          empty_space_after_addition = ((plex.size % current_plate.dimension) + current_plate.overlap)
          empty_space_after_addition <= ((plex.size >= current_plate.dimension) ? 0 : current_plate.dimension)
        end
      end.map(&:last)

      # Nothing fits optimally, apparently.  We suggest filling this with empty space!l
      return [ [Cherrypick::Strategy::Empty] * current_plate.remainder, requests ] if candidate_plexes.empty?

      # Now order those plexes such that the first in the list is the optimal packing for the plate.  This
      # means that, if the plate is empty, we can use the biggest; otherwise we're looking for the largest
      # plex that reduces empty space to a minimum.
      selected_plex, *remaining_plexes = candidate_plexes.sort do |left, right|
        if current_plate.overlap.zero?
          right.size <=> left.size
        else
          left_fill, right_fill = current_plate.space_after_adding(left), current_plate.space_after_adding(right)
          sorted_fill =  left_fill <=> right_fill
          sorted_fill = right.size <=> left.size if sorted_fill.zero?
          sorted_fill
        end
      end
      [ selected_plex, requests - selected_plex ]
    end
  end

  class PickPlate
    def initialize(purpose, filled = 0)
      @purpose, @wells = purpose, [Cherrypick::Strategy::Empty] * filled
    end

    delegate :size, :cherrypick_direction, :to => :@purpose

    # This is the size of the plate in the dimension in which we cherrypick.
    def dimension
      @dimension ||= Map.send(:"plate_#{cherrypick_direction == 'row' ? 'width' : 'length'}", size)
    end

    def available
      size - used
    end

    delegate :empty?, :inspect, :concat, :to => :@wells

    def used
      @wells.size
    end

    def space_after_adding(plex)
      (available - plex.size) % dimension
    end

    def overlap
      used % dimension
    end

    def remainder
      (dimension - overlap) % dimension
    end

    def to_a
      @wells.map(&:representation)
    end
  end

  Empty = Object.new.tap do |empty|
    class << empty
      def barcode
        nil
      end

      def representation
        [0, 'Empty', '']
      end

      # This well really isn't present!
      def present?
        false
      end

      def representation
        self
      end

      def inspect
        'Empty'
      end
    end
  end

  class Full
    def initialize(request)
      @request = request
    end

    def submission_id
      @submission_id ||= @request.submission_id
    end

    def barcode
      @barcode ||= @request.asset.plate.sanger_human_barcode
    end

    def representation
      @request
    end
  end

  def initialize(purpose)
    @purpose = purpose
  end

  def pick(requests, robot, plate = nil)
    _pick(requests.map(&Full.method(:new)), robot, wrap_plate(plate))
  end

  def create_empty_plate
    PickPlate.new(@purpose)
  end
  private :create_empty_plate

  # Given a, possibly nil, plate, create something that knows how to the pick of a plex will affect
  # that plate.  We assume that the space used on the specified plate is contiguous.  Sometimes
  # plates can be completely devoid of wells, in which case they can be treated as an empty plate
  # too.
  def wrap_plate(plate)
    return create_empty_plate if plate.nil?

    boundary_location = plate.wells.in_preferred_order.map { |w| w.map }.last or return create_empty_plate
    boundary_index    = plate.plate_purpose.well_locations.index(boundary_location) or
      raise "Cannot find #{boundary_location.inspect} on #{plate.id}"
    PickPlate.new(@purpose, boundary_index+1)
  end
  private :wrap_plate

  def _pick(requests, robot, current_plate = create_empty_plate)
    [].tap do |plate_picks|
      previous_picked_plates = []
      until requests.empty?
        # Here we keep selecting plexes according to our core strategy.  Should the selected plex violate
        # the number of beds on the robot, then we simply discard it and try again.  If there are no plexes
        # that fit, then we give up on this plate and move on to a new one.
        next_plex, pick_list = [], requests
        until pick_list.empty?
          next_plex, pick_list = choose_next_plex_from(pick_list, current_plate)
          plates_in_this_plex  = next_plex.map(&:barcode).compact

          break if next_plex.empty?                                                       # No plex fits what we want
          break if (plates_in_this_plex | previous_picked_plates).size <= robot.max_beds  # Good set of plates

          # Try to find a better option!
          next_plex = []
        end

        # If we've managed to pick stuff then add it to the current plate, remove it from the pick list,
        # and move on.  If we've not picked anything then the current plate can be considered complete,
        # in whatever fashion that is, so push it and move on.
        if not next_plex.empty?
          current_plate.concat(next_plex)
          requests, previous_picked_plates = requests - next_plex, previous_picked_plates | next_plex.map(&:barcode).compact
        elsif current_plate.empty?
          raise PickFailureError
        else
          plate_picks.push(current_plate)
          current_plate, previous_picked_plates = create_empty_plate, []
        end
      end
      plate_picks.push(current_plate) unless current_plate.empty?
    end.map(&:to_a)
  end
  private :_pick
end
