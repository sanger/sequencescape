
class AdjustRequestTypeAllocationToPipelines < ActiveRecord::Migration
  def self.all_keys
    %w(miseq_sequencing illumina_c_miseq_sequencing illumina_a_miseq_sequencing illumina_b_miseq_sequencing qc_miseq_sequencing)
  end

  def self.qc_keys
    ['qc_miseq_sequencing']
  end

  def self.standard_keys
    all_keys - qc_keys
  end

  def self.up
    ActiveRecord::Base.transaction do
      Pipeline.find_by(name: 'MiSeq sequencing').request_types = RequestType.where(key: standard_keys)
      Pipeline.find_by(name: 'MiSeq sequencing QC').request_types = RequestType.where(key: qc_keys)
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      Pipeline.find_by(name: 'MiSeq sequencing').request_types = RequestType.where(key: all_keys)
      Pipeline.find_by(name: 'MiSeq sequencing QC').request_types = RequestType.where(key: all_keys)
    end
  end
end
