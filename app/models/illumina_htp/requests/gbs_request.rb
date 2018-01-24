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

    Metadata.class_eval do
      belongs_to :primer_panel
      association(:primer_panel, :name)
      validates :primer_panel, presence: true
    end

    def update_pool_information(pool_information)
      super
      pool_information[:primer_panel] = request_metadata.primer_panel.summary_hash
    end
  end
end
