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

    # @note This is included below fragment_size_details
    # as fragment_size_details also invokes a {Request::Metadata} subclass
    # We'll need to simplify this at some point.
    include Request::HasPrimerPanel

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
  end
end
