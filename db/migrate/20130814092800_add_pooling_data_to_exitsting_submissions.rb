class AddPoolingDataToExitstingSubmissions < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do

      rids=RequestType.find_all_by_key(['illumina_a_isc','pulldown_isc','illumina_a_pulldown_isc']).map(&:id).join(',')

      Submission.find_each({
        :select => 'DISTINCT submissions.id',
        :joins => [
          "LEFT JOIN requests ON requests.submission_id = submissions.id AND requests.request_type_id IN (#{rids})",
          "LEFT JOIN request_metadata ON request_metadata.request_id = requests.id",
          "LEFT JOIN pre_capture_pool_pooled_requests ON pre_capture_pool_pooled_requests.request_id = requests.id"],
        :conditions => ['request_metadata.pre_capture_plex_level IS NOT NULL AND pre_capture_pool_pooled_requests.id IS NULL']
      }) do |sub|
        PreCapturePool::Builder.new(sub).build!
      end
    end
  end

  def self.down
    PreCapturePool.find_each(&:destroy)
  end
end
