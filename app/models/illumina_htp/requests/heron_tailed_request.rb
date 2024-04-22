# frozen_string_literal: true

module IlluminaHtp::Requests
  #
  # Class HeronRequest provides a means of tracking
  # Heron Tailed requests
  #
  # The heron process uses a very similar technique to GBS, however
  # rather than using the primer panel to amplify specific loci,
  # it uses a panel to amplify the entire SARS-CoV-2 genome.
  #
  # In the tailed process the library is processed in two parallel processes,
  # each of which applies duplicate tags. These two processes are later merged.
  # In order to allow for aliquot de-duplication when this merge occurs, we want
  # the same library id generated for both forks of the process. This is as
  # separate library ids would result in two aliquots in the merged tube, which
  # would violate the uniqueness constraint added to ensure tag uniqueness. In
  # order to achieve this we set the library id upfront. This is achieved by
  # adding it to the aliquot_attributes.
  #
  # Note: This may cause problems in future if two submissions are processed
  #       from the same cherrypicked plate, as both would share library ids.
  #
  # @author Genome Research Ltd.
  #
  class HeronTailedRequest < StdLibraryRequest
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
        library_id: asset_id,
        request_id: id
      }
    end
  end
end
