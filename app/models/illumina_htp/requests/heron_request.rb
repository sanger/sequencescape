# frozen_string_literal: true

module IlluminaHtp::Requests
  #
  # Class HeronRequest provides a means of tracking
  # Heron requests
  #
  # The heron process uses a very similar technique to GBS, however
  # rather than using the primer panel to amplify specific loci,
  # it uses a panel to amplify the entire SARS-CoV-2 genome.
  #
  # @author Genome Research Ltd.
  #
  class HeronRequest < StdLibraryRequest
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
        library_type:,
        insert_size:,
        primer_panel_id:,
        request_id: id
      }
    end
  end
end
