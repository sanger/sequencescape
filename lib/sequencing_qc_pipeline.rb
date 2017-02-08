# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011 Genome Research Ltd.
module SequencingQcPipeline
  # Returns Quality Control pipeline found using Regexp
  def qc_auto_pipeline_id
    Pipeline.find_by(name: 'quality control', automated: true).id
  end

  def self.qc_auto_pipeline
    Pipeline.find_by(name: 'quality control', automated: true)
  end

  def cluster_formation_pipeline_id
    Pipeline.where(sti_type: 'SequencingPipeline').pluck(:id)
  end

  def qc_pending_auto_batches
    Batch.most_recent(20).where(
      state: 'released', qc_state: 'qc_pending', qc_pipeline_id: id, pipeline_id: cluster_formation_pipeline_id
    ).includes(:user)
  end

  def qc_pending_manual_batches
    # {:state => "released", :qc_state => "qc_manual", :qc_pipeline_id => self.id},
    Batch.where([
      'qc_state = ? AND qc_pipeline_id = ? AND pipeline_id in (?)', 'qc_manual', id, cluster_formation_pipeline_id
    ]).order('created_at DESC').includes(:user)
  end

  def qc_in_progress_auto_batches
    # {:state => "released", :qc_state => "qc_criteria_received", :qc_pipeline_id => self.id},
    Batch.most_recent(20).where(['qc_state = ? OR qc_state = ? AND qc_pipeline_id = ? AND pipeline_id in (?)', 'qc_submitted', 'qc_criteria_received', id, cluster_formation_pipeline_id
      ]).includes(:user)
  end

  def qc_submitted_to_qc_batches
    Batch.most_recent(20).where(['qc_state = ?  AND qc_pipeline_id = ? AND pipeline_id in (?)', 'qc_submitted', id, cluster_formation_pipeline_id
      ]).includes(:user)
  end

  def qc_in_progress_manual_batches
    # {:state => "started", :qc_state => "qc_manual", :qc_pipeline_id => self.id},
    Batch.most_recent(20).where([
      'qc_state = ? AND qc_pipeline_id = ? AND pipeline_id in (?)', 'qc_manual_in_progress', id, cluster_formation_pipeline_id
    ]).includes(:user)
  end

  def qc_completed_auto_batches
    # {:state => "released", :qc_state => "qc_manual", :qc_pipeline_id => self.next_pipeline_id},
    Batch.most_recent(20).where(['qc_state = ? AND qc_pipeline_id = ? AND pipeline_id in (?)', 'qc_manual', next_pipeline_id, cluster_formation_pipeline_id
      ]).includes(:user)
  end

  def qc_completed_manual_batches
    # {:state => "released", :qc_state => "qc_completed", :qc_pipeline_id => self.id},
    Batch.most_recent(20).where([
      'qc_state = ? AND qc_pipeline_id = ? AND pipeline_id in (?)', 'qc_completed', id, cluster_formation_pipeline_id
    ]).includes(:user)
  end
end
