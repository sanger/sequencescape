# frozen_string_literal: true

module IlluminaHtp::Requests
  #
  # Class GbsRequest provides a means of tracking
  # Genotype by Sequencing requests
  #
  # @author Genome Research Ltd.
  #
  class GbsRequest < StdLibraryRequest
    fragment_size_details(:no_default, :no_default)
    delegate :primer_panel, to: :request_metadata

    Metadata.class_eval do
      belongs_to :primer_panel
      association(:primer_panel, :name)
      validates :primer_panel, presence: true
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
        primer_panel_id: primer_panel
      }
    end

    def update_pool_information(pool_information)
      super
      pool_information[:primer_panel] = request_metadata.primer_panel.summary_hash
    end
  end
end
