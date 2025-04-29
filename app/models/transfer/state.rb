# frozen_string_literal: true

# Provides scopes and methods to help find assets based on their state
module Transfer::State
  # These are all of the valid states but keep them in a priority order: in other words, 'started' is more important
  # than 'pending' when there are multiple requests (like a plate where half the wells have been started, the others
  # are failed).
  ALL_STATES = %w[started qc_complete pending passed failed cancelled].freeze

  def self.state_helper(names)
    names.each { |name| module_eval { define_method("#{name}?") { state == name } } }
  end

  state_helper(ALL_STATES)

  # The state of an asset is based on the transfer requests for the asset.  If they are all in the same
  # state then it takes that state.  Otherwise we take the "most optimum"!
  def state
    state_from(transfer_requests_as_target)
  end

  def default_state
    nil
  end

  def state_from(state_requests)
    unique_states = state_requests.map(&:state).uniq
    return unique_states.first if unique_states.size == 1

    ALL_STATES.detect { |s| unique_states.include?(s) } || default_state || 'unknown'
  end

  # Plate specific behaviour
  module PlateState
    def self.included(base) # rubocop:todo Metrics/MethodLength
      base.class_eval do
        scope :in_state,
              lambda { |states|
                states = Array(states).map(&:to_s)

                # If all of the states are present there is no point in actually adding this set of conditions because
                # we're basically looking for all of the plates.
                if states.sort != ALL_STATES.sort
                  # Note that 'state IS NULL' is included here for plates that are stock plates, because they will not
                  # have any transfer requests coming into their wells and so we can assume they are pending (from the
                  # perspective of pulldown at least).
                  query_conditions = +'transfer_requests.state IN (?)'
                  if states.include?('pending')
                    query_conditions << ' OR (transfer_requests.state IS NULL AND plate_purposes.stock_plate=TRUE)'
                  end

                  joins(:transfer_requests_as_target, :plate_purpose).where([query_conditions, states])
                else
                  all
                end
              }
      end
    end
  end

  # Tube specific behaviour
  module TubeState
    def self.included(base) # rubocop:todo Metrics/MethodLength
      base.class_eval do
        scope :in_state,
              lambda { |states|
                states = Array(states).map(&:to_s)

                # If all of the states are present there is no point in actually adding this set of conditions because
                # we're basically looking for all of the tubes.
                if states.sort != ALL_STATES.sort
                  join_options = [
                    # rubocop:todo Layout/LineLength
                    'LEFT OUTER JOIN `transfer_requests` transfer_requests_as_target ON transfer_requests_as_target.target_asset_id = `assets`.id'
                    # rubocop:enable Layout/LineLength
                  ]

                  joins(join_options).where(transfer_requests_as_target: { state: states })
                else
                  all
                end
              }
        scope :without_finished_tubes,
              lambda { |purpose|
                where.not(
                  ["assets.plate_purpose_id IN (?) AND transfer_requests_as_target.state = 'passed'", purpose.map(&:id)]
                )
              }
      end
    end
  end
end
