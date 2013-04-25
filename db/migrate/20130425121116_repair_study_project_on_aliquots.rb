class RepairStudyProjectOnAliquots < ActiveRecord::Migration

  def self.up
    ActiveRecord::Base.transaction do
      Well.last # Silly class loading work arround
      Request.find_each(
        :joins => "LEFT OUTER JOIN assets AS sa ON requests.asset_id = sa.id
      LEFT OUTER JOIN aliquots AS al ON al.receptacle_id = sa.id
      LEFT OUTER JOIN request_types ON request_types.id = requests.request_type_id",
        :conditions => "(al.study_id != requests.initial_study_id OR al.project_id != requests.initial_project_id) AND request_types.name IN('Illumina-A Pulldown WGS','Illumina-A Pulldown SC','Illumina-A Pulldown ISC','Illumina-B STD')"
        ) do |request|
        say "Processing request #{request.id}"
        cross_study = request.target_asset.aliquots.map(&:study_id).uniq.count
        say "-- Pools #{cross_study} studies"
        repair(request)
      end
    end
  end

  def self.down
  end

  def self.repair(request)
    ActiveRecord::Base.transaction do
      raise "Multiple Aliquots Discovered" if request.asset.aliquots.count > 1
      raise "No Aliquots Discovered" if request.asset.aliquots.count == 0
      parent_aliquot = request.asset.aliquots.first
      study_id = request.study_id
      project_id = request.initial_project_id
      request.asset.requests.reject {|r| r.is_a?(Request::LibraryCreation)}.each do |request|
        step_repair(request,parent_aliquot,study_id,project_id)
      end
    end
  end

  def self.step_repair(request,parent_aliquot,study_id,project_id)
    return if request.target_asset.nil?
    return if request.target_asset.aliquots.empty?
    if ((request.initial_study_id||study_id)!=study_id )||((request.initial_project_id||project_id)!=project_id )
      say "Downstream request mismatch: #{request.id}, skipping this branch"
      return
    end
    aliquot = find_aliquot(request.target_asset,parent_aliquot)
    aliquot.study_id = study_id
    aliquot.project_id = project_id
    aliquot.save!
    request.target_asset.requests.each do |new_request|
      step_repair(new_request,aliquot,study_id,project_id)
    end
    request.clear_association_cache
  end

  def self.find_aliquot(asset,parent_aliquot)
    potential_aliquots = asset.aliquots.select {|a|
      a.sample_id == parent_aliquot.sample_id &&
      (parent_aliquot.tag_id == a.tag_id || parent_aliquot.tag_id==-1)  &&
      (parent_aliquot.library_id || a.library_id) == a.library_id
    }
    raise "Multiple Children detected: #{potential_aliquots.map(&:id)}" if potential_aliquots.count > 1
    potential_aliquots.first
  end
end
