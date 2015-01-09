##
# Set on a multiplexed request_type
# Pools based on the submission.
module RequestType::PoolingMethod::Submission
  def pool_count
    1
  end

  def pool_index_for(_)
    0
  end
end
