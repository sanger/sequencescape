# frozen_string_literal: true

# Include in {Request} classes to add tracking of {PrimerPanel primer panels}
# Sets up:
# - An {Attributable::association} for primer_panel (Used to help render forms for requests)
# - Sets primer_panel as required on create
# - Adds primer_panel and primer_panel_id methods to the request
# - Adds primer panel information to the pool_information
# @note The actual primer_panel association is set-up on {Request::Metadata}
module Request::HasPrimerPanel
  extend ActiveSupport::Concern

  included do
    delegate :primer_panel, :primer_panel_id, to: :request_metadata

    self::Metadata.class_eval do
      association(:primer_panel, :name)
      # ON create, check our actual primer panel
      validates :primer_panel, presence: true, on: :create
    end
  end

  def update_pool_information(pool_information)
    super
    pool_information[:primer_panel] = request_metadata.primer_panel.summary_hash
  end
end
