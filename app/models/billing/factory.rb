module Billing
  module Factory
    SEQUENCING_REQUEST_TYPES = %w(illumina_c_miseq_sequencing illumina_c_hiseq_2500_paired_end_sequencing
                                  illumina_b_hiseq_2500_paired_end_sequencing illumina_b_hiseq_2500_single_end_sequencing
                                  illumina_c_hiseq_2500_single_end_sequencing illumina_b_miseq_sequencing
                                  illumina_b_hiseq_v4_paired_end_sequencing illumina_c_hiseq_v4_paired_end_sequencing
                                  illumina_b_hiseq_x_paired_end_sequencing illumina_c_hiseq_v4_single_end_sequencing
                                  bespoke_hiseq_x_paired_end_sequencing illumina_htp_hiseq_4000_paired_end_sequencing
                                  illumina_c_hiseq_4000_paired_end_sequencing).freeze

    LIBRARY_CREATION_REQUEST_TYPES = %w(limber_wgs limber_isc limber_pcr_free limber_lcmb).freeze

    def self.build(request)
      return Sequencing.new(request: request) if SEQUENCING_REQUEST_TYPES.include?(request.request_type.key)
      return LibraryCreation.new(request: request) if LIBRARY_CREATION_REQUEST_TYPES.include?(request.request_type.key)
      Base.new(request: request)
    end
  end
end
