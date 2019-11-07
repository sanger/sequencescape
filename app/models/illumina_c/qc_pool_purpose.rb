# Used in Generic Lims and Illumina-B Pipeline to represent MiSeq QC tube purposes.
# @see file:docs/associated_applications.md
# A MiSeq QC tube is a pool of an entire plate which is submitted to the
# MiSeq {SequencingPipeline} for QC purposes. (Largely to check representation
# of each sample within the pool)
#
# While the high throughput PCR-Free pipeline was migrated to Limber, this Purpose
# class is no longer used by any active pipelines.
#
# @deprecated Part of non-longer active pipelines, or older variants.
#             On 2019-10-01 was last used 2017-08-02 14:36:05 +0100
#
# @todo #2396 Remove this class. This will required:
#
#       - Update any purposes using this class to use Tube::Purpose instead
#       - Update:
#           app/models/illumina_c/plate_purposes.rb
#           illumina_htp/plate_purposes.rb
#         By either replacing with Tube::Purpose, or removing the factories entirely
class IlluminaC::QcPoolPurpose < Tube::Purpose
  # Updates the state of tube to state
  # @param tube [Tube] The tube being updated
  # @param state [String] The desired target state
  # @param _user [User] Provided for interface compatibility
  # @param _ [nil, Array] Provided for interface compatibility
  # @param _customer_accepts_responsibility [Boolean] Provided for interface compatibility
  #
  # @return [Void]
  def transition_to(tube, state, _user, _ = nil, _customer_accepts_responsibility = false)
    ActiveRecord::Base.transaction do
      tube.transfer_requests_as_target.where.not(state: terminated_states).find_each do |request|
        request.transition_to(state)
      end
    end
  end

  def terminated_states
    %w[cancelled failed]
  end
  private :terminated_states
end
