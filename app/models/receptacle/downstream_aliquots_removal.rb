# frozen_string_literal: true

# DPL-451: Added functonality to not remove aliquots when failing plates that have a sequencing batch
# downstream
module Receptacle::DownstreamAliquotsRemoval
  # Public interface for the downstream aliquots removal functionality, part of the Receptacle interface
  module Mixin
    # Returns a boolean that indicates if it is valid to remove downstream aliquots starting from this one.
    # Current condition (DPL-451) estimates that if the labware has descendants that are involved
    # in a sequencing batch, we do not remove any data from downstream aliquots or from MLWH.
    #
    # @return [Boolean] true if we allow to remove downstream aliquots, false otherwise
    def allow_to_remove_downstream_aliquots?
      creation_batches = PrivateMethods.creation_batches_for_requests(self)
      creation_batches.nil? || creation_batches.flatten.uniq.empty?
    end
  end

  # Private methods to provide functionality for the mixin
  module PrivateMethods
    # Gets the submissions of all outer requests that wrap this well
    #
    # @param instance [Receptacle] The well we want to obtain submissions from
    #
    # @return [Array[Submission]] List of submissions
    def self.submissions_for_requests(instance)
      instance.aliquot_requests.map(&:submission)&.flatten&.uniq || []
    end

    # Get the sequencing creations batches by following the outer requests graph.
    # Supposing this outer requests graph:
    # Library Creation ---> Multiplexing --> Sequencing
    # The path to solve the creation batches is as follows:
    # 1) Get the submissions from the outer requests that wrap this current node
    # 2) From each submission, get the multiplexed labware, which is the labware
    #    that is the target of a multiplexed request (outer request before sequencing)
    # 3) From this multiplexed labware, it goes to the next labware created from it (sequencing tube).
    # 4) For this labware, it access to the creation batches (groups of sequencing requests that will go into
    #    a flowcell)
    # 5) It returns the aggregation of all creation batches from all submissions
    #
    # @param instance [Receptacle] The well we want to obtain creation batche from
    #
    # @return [Array[Batch]] List of batches
    def self.creation_batches_for_requests(instance)
      PrivateMethods
        .submissions_for_requests(instance)
        .map do |submission|
          submission&.multiplexed_labware&.children&.map(&:creation_batches) # rubocop:disable Style/SafeNavigationChainLength
        end
        .flatten
        .compact
    end
  end
end
