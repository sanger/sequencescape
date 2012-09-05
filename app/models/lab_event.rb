class LabEvent < ActiveRecord::Base
  belongs_to :batch
  belongs_to :user
  belongs_to :eventful, :polymorphic => true
  acts_as_descriptable :serialized

  before_validation :unescape_for_descriptors

  named_scope :with_descriptor, lambda { |k,v| { :conditions => [ 'descriptors LIKE ?', "%#{k.to_s}: #{v.to_s}%" ] } }

  named_scope :barcode_code, lambda { |*args| {:conditions => ["description = 'Cluster generation' and eventful_type = 'Request' and descriptors like ? ", args[0]] }}


  def unescape_for_descriptors
    self[:descriptors] = (self[:descriptors] || {}).inject({}) do |hash,(key,value)|
      hash[ CGI.unescape(key) ] = value
      hash
    end
  end

  def self.find_by_barcode(barcode)
    batch_id = 0

    search = "%Chip Barcode: " + barcode +"%"
    requests = self.barcode_code(search)
    batch = requests.map(&:batch_id).uniq
    batch_id = batch[0] unless batch.size != 1

    return batch_id
  end

  def descriptor_value_for(name)
    self.descriptors.each do |desc|
      if desc.name.eql?(name.to_s)
        return desc.value
      end
    end
    return nil
  end

  def add_new_descriptor(name, value)
    add_descriptor Descriptor.new(:name => name, :value => value)
  end
end
