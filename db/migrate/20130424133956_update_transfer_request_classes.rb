class UpdateTransferRequestClasses < ActiveRecord::Migration

  def self.each_parent_and_child
    [
      {
        :parent=>'ILB_STD_INPUT', :child=>'ILB_STD_COVARIS',
        :request_class_name=>'IlluminaB::Requests::InputToCovaris', :prefix=>'Illumina-B'
        },
        {
        :parent=>'WGS stock DNA', :child=>'WGS Covaris',
        :request_class_name=>'Pulldown::Requests::StockToCovaris', :prefix=>'Pulldown'
        },
        {
        :parent=>'SC stock DNA', :child=>'SC Covaris',
        :request_class_name=>'Pulldown::Requests::StockToCovaris', :prefix=>'Pulldown'
        },
        {
        :parent=>'ISC stock DNA', :child=>'ISC Covaris',
        :request_class_name=>'Pulldown::Requests::StockToCovaris', :prefix=>'Pulldown'
        }
    ].each do |settings|
      yield(
        Purpose.find_by_name!(settings[:parent]),
        Purpose.find_by_name!(settings[:child]),
        request_type(settings))
    end
  end

  def self.request_type(settings)
    parent = settings[:parent]
    prefix = settings[:prefix]
    child  = settings[:child]
    request_class = settings[:request_class_name]
    request_type_name = "#{prefix} #{parent}-#{child}"
    RequestType.find_by_name(request_type_name)||RequestType.create!(:name => request_type_name, :key => request_type_name.gsub(/\W+/, '_'), :request_class_name => request_class, :asset_type => 'Well', :order => 1)
  end

  def self.up
    ActiveRecord::Base.transaction do
      each_parent_and_child do |parent,child,request_type|
        parent.child_relationships.detect do |r|
          r.child == child
        end.update_attributes!(:transfer_request_type=>request_type)
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      each_parent_and_child do |parent,child,request_type|
        parent.child_relationships.detect do |r|
          r.child == child
        end.update_attributes!(:transfer_request_type=>RequestType.transfer)
      end
    end
  end
end
