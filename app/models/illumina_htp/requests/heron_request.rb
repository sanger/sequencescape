# frozen_string_literal: true

module IlluminaHtp::Requests
  #
  # Class HeronRequest provides a means of tracking
  # Heron requests
  #
  # @author Genome Research Ltd.
  #
  class HeronRequest < StdLibraryRequest
    fragment_size_details(:no_default, :no_default)
    delegate :primer_panel, :primer_panel_id, to: :request_metadata

    Metadata.class_eval do
      belongs_to :primer_panel
      association(:primer_panel, :name)
      # ON create, check our actual primer panel
      validates :primer_panel, presence: true, on: :create
    end

    #
    # Passed into cloned aliquots at the beginning of a pipeline to set
    # appropriate options
    #
    #
    # @return [Hash] A hash of aliquot attributes
    #
    def aliquot_attributes
      {
        study_id: initial_study_id,
        project_id: initial_project_id,
        library_type: library_type,
        insert_size: insert_size,
        primer_panel_id: primer_panel_id,
        request_id: id
      }
    end

    def update_pool_information(pool_information)
      super
      pool_information[:primer_panel] = request_metadata.primer_panel.summary_hash
    end
  end
end
