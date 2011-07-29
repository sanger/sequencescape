class GroupPipelines < ActiveRecord::Migration
  def self.up
    {
      'Library creation' => [
        'Library preparation',
        'MX Library creation',
        'MX Library Preparation [NEW]',
        'Pulldown library preparation',
        'Pulldown Multiplex Library Preparation',
        'Pulldown WGS',
        'Pulldown SC',
        'Pulldown ISC'
      ],
      'Sequencing' => [
        'Cluster formation (old)',
        'Cluster formation SE HiSeq (spiked in controls)',
        'Cluster formation SE (spiked in controls)',
        'Cluster formation SE (no controls)',
        'Cluster formation SE HiSeq (no controls)',
        'Cluster formation SE HiSeq',
        'Cluster formation SE',
        'Cluster formation PE',
        'Cluster formation PE (spiked in controls)',
        'HiSeq Cluster formation PE (no controls)',
        'HiSeq Cluster formation PE (spiked in controls)',
        'Cluster formation PE (no controls)'
      ],
      'Sample Logistics' => [
        'DNA QC',
        'Cherrypick',
        'Genotyping',
        'Cherrypicking for Pulldown'
      ],
      'R&D' => [
        'PacBio Sample Prep',
        'PacBio Sequencing'
      ],
      'QC' => [
        'Manual Quality Control',
        'Quality Control'
      ]
    }.each do |group_name, pipelines|
      Pipeline.update_all("group_name=#{group_name.inspect}", [ 'name IN (?)', pipelines ])
    end
  end

  def self.down
    # Nothing needed here because the column will be removed
  end
end

