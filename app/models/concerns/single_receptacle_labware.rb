# frozen_string_literal: true

# Labware with just a single receptacle
# This is mostly compatibility methods and we should consider removing
# as we migrate
module SingleReceptacleLabware
  extend ActiveSupport::Concern

  included do
    has_one :receptacle, foreign_key: :labware_id, inverse_of: :labware, dependent: :destroy, autosave: true
    has_one :primary_aliquot, through: :receptacle
    has_one :primary_sample, through: :receptacle
    has_one :source_request, through: :receptacle
    has_many :sample_manifest_assets, through: :receptacle
    # Ensure we generate the receptacle automatically when the labware is created
    before_validation :receptacle, on: :create

    # Previously we used to delegate all aliquot activity to the relationship
    # on receptacle, but this massively disrupted eager-loading, causing major
    # performance issues on the API. Without this delegation attempts to set
    # aliquots on a labware fail, as Rails can't set receptacle_id.
    delegate :aliquots=, to: :receptacle

    delegate :concentration, :concentration=, to: :receptacle

    # And a few more basic delegations
    delegate  :qc_state, :qc_state=,
              :external_release, :external_release=,
              :volume, :volume=,
              :closed, :closed=,
              :primary_aliquot_if_unique,
              :source_request,
              :resource, :resource=,
              :register_stock!,
              to: :receptacle

    scope :include_aliquots_for_api, -> { includes(receptacle: { aliquots: Io::Aliquot::PRELOADS }) }
  end

  def receptacle
    super || build_receptacle(sti_type: receptacle_class)
  end
end
