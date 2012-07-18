class AddPcrXpToStockRequestType < ActiveRecord::Migration
  def self.bind_purposes(&block)
    ActiveRecord::Base.transaction do
      pcrxp_purpose = Purpose.find_by_name('ILB_STD_PCRXP') or raise "Cannot find PCR XP plate purpose"
      stock_purpose = Purpose.find_by_name('ILB_STD_STOCK') or raise "Cannot find stock tube purpose"
      name = 'Illumina-B - ILB_STD_PCRXP-ILB_STD_STOCK'
      yield(pcrxp_purpose, stock_purpose, name, name.gsub(/\W+/, '_'))
    end
  end

  def self.up
    bind_purposes do |pcrxp_purpose, stock_purpose, name, key|
      request_type  = RequestType.create!(:name => name, :key => key, :request_class_name => 'IlluminaB::Requests::PcrXpToStock', :asset_type => 'Well', :order => 1)
      pcrxp_purpose.child_relationships.create!(:child => stock_purpose, :transfer_request_type => request_type)
    end
  end

  def self.down
    bind_purposes do |pcrxp_purpose, stock_purpose, _, key|
      RequestType.find_by_key(key).tap do |request_type|
        pcrxp_purpose.child_relationships.all(:conditions => { :transfer_request_type_id => request_type.id }).map(&:destroy)
      end.destroy
    end
  end
end
