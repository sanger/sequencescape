class AddTriggersForInitialVolumeUpdate < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      execute('CREATE TRIGGER insert_initial_volume BEFORE INSERT ON well_attributes
FOR EACH ROW SET NEW.initial_volume = IFNULL(NEW.initial_volume,NEW.measured_volume);')
      execute('CREATE TRIGGER update_initial_volume BEFORE UPDATE ON well_attributes
FOR EACH ROW
BEGIN
  IF (NEW.initial_volume IS NULL AND NEW.measured_volume IS NOT NULL) THEN
    SET NEW.initial_volume = IFNULL(OLD.initial_volume, NEW.measured_volume);
  END IF;
END;')
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      execute('DROP TRIGGER insert_initial_volume;')
      execute('DROP TRIGGER update_initial_volume;')
    end
  end
end
