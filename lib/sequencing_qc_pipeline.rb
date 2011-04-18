module SequencingQcPipeline
  # Returns Quality Control pipeline found using Regexp
  def qc_auto_pipeline_id
    Pipeline.first(:conditions => {:name => "quality control", :automated => true}).id
  end

  def self.qc_auto_pipeline
    Pipeline.first(:conditions => {:name => "quality control", :automated => true})
  end

  def cluster_formation_pipeline_id
    Pipeline.find_all_by_sti_type("SequencingPipeline").map(&:id)
  end

  def qc_pending_auto_batches
    Batch.find(:all,
      :conditions => ["state = ? AND qc_state = ? AND qc_pipeline_id = ? AND pipeline_id in (?)", "released", "qc_pending", self.id, cluster_formation_pipeline_id],
      :limit => 20, :order => "created_at DESC", :include => [:user])
  end

  def qc_pending_manual_batches
    # {:state => "released", :qc_state => "qc_manual", :qc_pipeline_id => self.id},
    Batch.find(:all,
    :conditions => ["qc_state = ? AND qc_pipeline_id = ? AND pipeline_id in (?)", "qc_manual", self.id, cluster_formation_pipeline_id],
    :order => "created_at DESC", :include => [:user])
  end

  def qc_in_progress_auto_batches
    # {:state => "released", :qc_state => "qc_criteria_received", :qc_pipeline_id => self.id},
    Batch.find(:all,
      :conditions => ["qc_state = ? OR qc_state = ? AND qc_pipeline_id = ? AND pipeline_id in (?)", "qc_submitted", "qc_criteria_received", self.id, cluster_formation_pipeline_id],
      :order => "created_at DESC", :limit => 20, :include => [:user])
  end

  def qc_submitted_to_qc_batches
    Batch.find(:all,
      :conditions => ["qc_state = ?  AND qc_pipeline_id = ? AND pipeline_id in (?)", "qc_submitted", self.id, cluster_formation_pipeline_id],
      :order => "created_at DESC", :limit => 20, :include => [:user])
  end

  def qc_in_progress_manual_batches
    # {:state => "started", :qc_state => "qc_manual", :qc_pipeline_id => self.id},
    Batch.find(:all,
    :conditions => ["qc_state = ? AND qc_pipeline_id = ? AND pipeline_id in (?)", "qc_manual_in_progress", self.id, cluster_formation_pipeline_id],
    :order => "created_at DESC", :limit => 20, :include => [:user])
  end

  def qc_completed_auto_batches
    # {:state => "released", :qc_state => "qc_manual", :qc_pipeline_id => self.next_pipeline_id},
    Batch.find(:all,
      :conditions => ["qc_state = ? AND qc_pipeline_id = ? AND pipeline_id in (?)", "qc_manual", self.next_pipeline_id, cluster_formation_pipeline_id],
      :order => "created_at DESC", :limit => 20, :include => [:user])
  end

  def qc_completed_manual_batches
    # {:state => "released", :qc_state => "qc_completed", :qc_pipeline_id => self.id},
    Batch.find(:all,
    :conditions => ["qc_state = ? AND qc_pipeline_id = ? AND pipeline_id in (?)", "qc_completed", self.id, cluster_formation_pipeline_id],
    :order => "created_at DESC", :limit => 20, :include => [:user])
  end

end
