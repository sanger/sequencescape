class AddParentPurposeToPlateCreators < ActiveRecord::Migration

  def self.build_purpose_config_record(plate_purpose_name, parent_purpose_name)
    {
      :plate_purpose => Purpose.find_by_name!(plate_purpose_name),
      :parent_purpose => Purpose.find_by_name!(parent_purpose_name)
    }
  end

  def self.purposes_config
    [
      build_purpose_config_record("Working dilution", "Stock plate"),
      build_purpose_config_record("Pico dilution", "Working dilution"),
      build_purpose_config_record("Pico Assay Plates", "Pico dilution")
    ]
  end

  def self.validate_purposes_config(purposes_config)
    purposes_config.all? { |p| !p[:plate_purpose].nil? && !p[:parent_purpose].nil? }
  end

  def self.up
    unless self.validate_purposes_config(self.purposes_config)
      raise ActiveRecord::Rollback
    end
    ActiveRecord::Base.transaction do
      self.purposes_config.each do |p|
        relations = Plate::Creator::PurposeRelationship.find(:all, :conditions => {
          :plate_purpose_id => p[:plate_purpose].id
        })
        if (relations.length == 0)
          Plate::Creator.find(:all, :conditions => {
            :plate_purpose_id => p[:plate_purpose].id
          } ).each do |c|
            Plate::Creator::PurposeRelationship.create!({
              :plate_creator_id => c.id,
              :plate_purpose_id => p[:plate_purpose].id,
              :parent_purpose_id => p[:parent_purpose].id
            })
          end
        else
          relations.each do |r|
            r.update_attributes!(:parent_purpose_id =>  p[:parent_purpose].id)
          end
        end
      end
    end
  end

  def self.down
    unless self.validate_purposes_config(self.purposes_config)
     raise ActiveRecord::Rollback
    end
    ActiveRecord::Base.transaction do
      self.purposes_config.each do |p|
        Plate::Creator::PurposeRelationship.find(:all, :conditions => {
          :plate_purpose_id => p[:plate_purpose].id
        }).each do |r|
          r.update_attributes!(:parent_purpose_id =>  nil)
        end
      end
    end
  end
end
