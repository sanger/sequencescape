# frozen_string_literal: true
# Represents multiplex pooling source intermediate plates with
# Well::Link of type stock such as:
#
# - LB Cap Lib PCR-XP
#
class PoolingSourcePlatePurpose < PlatePurpose
  private

  # Because this plate purpose has Well::Link of type stock, we can treat it like an input plate
  # and use the scope that fetches the source multiplexing submission
  def _pool_wells(wells)
    source_pooled_wells = wells.pooled_as_source_by(Request::Multiplexing)
    return source_pooled_wells if source_pooled_wells.exists?

    wells.pooled_as_target_by_transfer
  end
end
