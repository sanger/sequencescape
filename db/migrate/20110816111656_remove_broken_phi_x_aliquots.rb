class RemoveBrokenPhiXAliquots < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      # Remove any aliquots that have been bound to a receptacle that has since disappeared, for some reason.
      Sample.find_by_name('phiX_for_spiked_buffers').aliquots.each do |aliquot|
        aliquot.destroy if aliquot.receptacle_id.nil? or aliquot.receptacle.nil?
      end
    end
  end

  def self.down
    # Doesn't need to do anything on the down
  end
end
