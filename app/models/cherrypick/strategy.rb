# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2012,2013,2014,2015 Genome Research Ltd.

class Cherrypick::Strategy
  PickFailureError = Class.new(StandardError)

  # Classes inside this module represent filters that can be combined to reduce the set of plexes
  # for a cherrypick to the optimum selection.
  module Filter
    # Shortens any plexes over the available space of the plate to fit.
    class ShortenPlexesToFit
      def call(plexes, current_plate)
        plexes.map { |p| p.slice(0, current_plate.available) }
      end
    end

    # Ensures that the plate is not overflowed by any of the plexes.
    class ByOverflow
      def call(plexes, current_plate)
        plexes.select { |plex| (plex.size + current_plate.used) <= current_plate.size }
      end
    end

    # Ensures that the plexes do not overflow the dimension of the plate when added.
    class ByEmptySpaceUsage
      def call(plexes, current_plate)
        return plexes if current_plate.overlap.zero?

        plexes.select do |plex|
          empty_space_after_addition = (plex.size + current_plate.overlap) % current_plate.dimension
          empty_space_after_addition <= ((plex.size >= current_plate.dimension) ? 0 : current_plate.dimension)
        end
      end
    end

    # Orders the plexes by the optimum fitting
    class BestFit
      def call(plexes, current_plate)
        comparator = ->(l, r) { r.size <=> l.size }
        comparator = lambda do |left, right|
          left_fill, right_fill = current_plate.space_after_adding(left), current_plate.space_after_adding(right)
          sorted_fill = left_fill <=> right_fill
          sorted_fill = right.size <=> left.size if sorted_fill.zero?
          sorted_fill
        end unless current_plate.overlap.zero?

        plexes.sort(&comparator)
      end
    end

    # Orders the plexes such that plexes with the same species as the plate come first, ensuring that
    # the plate has species closely packed.  We're going to assume that if the well has multiple samples
    # in it, then any of those species is a good choice.  Ordering is maintained within plexes, that is,
    # appropriate plexes bubble to the top but maintain their relative ordering; this means filters that
    # apply an ordering can be used before this.
    class BySpecies
      def call(plexes, current_plate)
        species = current_plate.species
        return plexes if species.empty?

        plexes.each_with_index.sort do |(left, left_index), (right, right_index)|
          left_species, right_species = species_for_plex(left), species_for_plex(right)
          left_in, right_in = species & left_species, species & right_species
          case
          when  left_in.empty? &&  right_in.empty? then left_index <=> right_index # No match (maintain order)
          when !left_in.empty? && !right_in.empty? then left_index <=> right_index # Both match (maintain order)
          when !left_in.empty?                     then -1                         # Left better
          else                                           1                         # Right better
          end
        end.map(&:first)
      end

      def species_for_plex(plex)
        plex.map(&:species).flatten.uniq.sort
      end
      private :species_for_plex
    end

    # Ensures that all of the plexes are internally ordered based on their position in the submission
    class InternallyOrderPlexBySubmission
      def call(plexes, _current_plate)
        plexes.map do |plex|
          plex.sort_by(&:index_in_submission)
        end
      end
    end

    class InRowOrder
      def call(plexes, _current_plate)
        plexes.map do |plex|
          plex.sort_by(&:row_index)
        end
      end
    end

    class InColumnOrder
      def call(plexes, _current_plate)
        plexes.map do |plex|
          plex.sort_by(&:column_index)
        end
      end
    end
  end

  class PickPlate
    def initialize(purpose, filled = 0, species = [])
      @purpose, @wells, @species = purpose, [Cherrypick::Strategy::Empty] * filled, species
    end

    delegate :size, :cherrypick_direction, to: :@purpose

    # This is the size of the plate in the dimension in which we cherrypick.
    def dimension
      @dimension ||= Map::Coordinate.send(:"plate_#{cherrypick_direction == 'row' ? 'width' : 'length'}", size)
    end

    def available
      size - used
    end

    delegate :empty?, :inspect, :concat, to: :@wells

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

    def species
      @wells.map(&:species).reject(&:empty?).last || @species
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

      # This well really isn't present!
      def present?
        false
      end

      def representation
        self
      end

      def species
        []
      end

      def inspect
        'Empty'
      end

      def row_index
        nil
      end

      def column_index
        nil
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

    def index_in_submission
      @index_in_submission ||= @request.submission.requests.index(@request)
    end

    def barcode
      @barcode ||= @request.asset.plate.sanger_human_barcode
    end

    def representation
      @request
    end

    def species
      @request.asset.aliquots.map { |a| a.sample.sample_metadata.sample_common_name }
    end

    def row_index
      @request.asset.map.row_order
    end

    def column_index
      @request.asset.map.column_order
    end
  end

  def initialize(purpose)
    @purpose = purpose
  end

  delegate :cherrypick_filters, to: :@purpose
  private :cherrypick_filters

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

    # Identify the last well (empty or not) on the plate as the point at which we start the pick
    boundary_location = plate.wells.in_preferred_order.map { |w| w.map }.last or return create_empty_plate
    boundary_index    = plate.plate_purpose.well_locations.index(boundary_location) or
      raise "Cannot find #{boundary_location.inspect} on #{plate.id}"

    # Pick out the last full well of the plate as the species we're supposed to use
    last_well, species = plate.wells.in_preferred_order.reject { |w| w.aliquots.empty? }.last, []
    species = last_well.aliquots.map { |a| a.sample.sample_metadata.sample_common_name }.uniq.sort if last_well.present?

    PickPlate.new(@purpose, boundary_index + 1, species)
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

  # Picking the next plex involves applying each of the filters we have to the requests and then
  # taking the first.  The filters therefore reduce the set of requests, ordering them if desired,
  # before we decide if there is a plex that's appropriate.
  def choose_next_plex_from(requests, current_plate)
    candidate_plexes = cherrypick_filters.map(&:new).inject(requests.group_by(&:submission_id).map(&:last)) do |plexes, filter|
      filter.call(plexes, current_plate)
    end

    return [[Cherrypick::Strategy::Empty] * current_plate.remainder, requests] if candidate_plexes.empty?
    [candidate_plexes.first, requests - candidate_plexes.first]
  end
  private :choose_next_plex_from
end
