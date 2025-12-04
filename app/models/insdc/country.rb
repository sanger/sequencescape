# frozen_string_literal: true

module Insdc
  # Provides a controlled vocabulary describing names of countries or oceans/seas
  # in accordance with the INSDC (https://www.insdc.org/)
  #
  # In addition the list may contain non-geographic identifiers that are
  # permitted by the EBI sample checklists (eg 'not collected') An example
  # EBI checklist may be found here: https://www.ebi.ac.uk/ena/browser/view/ERC000011
  #
  # The list can be populated via the rake:task
  # `bundle exec rake insdc:countries:import`
  #
  # To import from an alternative sample sheet, use
  # `bundle exec rake insdc:countries:import[other_accession]`
  # @note be aware you may need to escape the square brackets if using zsh
  class Country < ApplicationRecord
    include SharedBehaviour::Named

    # @!attribute [rw] :name
    #   @return [String] The name of the country, ocean, sea or permitted non-geographic region
    attribute :name, :string

    # @!attribute [rw] :sort_priority
    #   Higher sort priorities are sorted towards the top of dropdown lists to aid picking
    #   @return [Integer] The priority of the region
    attribute :sort_priority, :integer, default: 0

    # @!attribute [rw] :validation_state
    #   Indicates if a region is valid for selection or not
    #   @note This has been implemented as an enum for flexible extension at a later date.
    #   @return [Symbol] :valid or :invalid
    enum :validation_state, { valid: 0, invalid: 1 }, suffix: :state

    validates :name, presence: true, uniqueness: { case_sensitive: false }
    validates :sort_priority, presence: true
    validates :validation_state, presence: true

    # Sorts countries in priority order, with those with the highest priority appearing
    # at the front of the list.
    scope :prioritized, -> { order(sort_priority: :desc) }

    # Filters all valid countries, sorted with higher priority options towards the top,
    # with the remaining entries alphabetical.
    scope :sorted_for_select, -> { valid_state.prioritized.alphabetical }

    def self.options
      sorted_for_select.pluck(:name)
    end

    def valid!
      update!(validation_state: :valid)
    end

    def invalid!
      update!(validation_state: :invalid)
    end
  end
end
