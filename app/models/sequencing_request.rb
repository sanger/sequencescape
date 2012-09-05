class SequencingRequest < Request
  READ_LENGTHS = [37, 54, 76, 108]
  has_metadata :as => Request  do
    #redundant with library creation , but THEY are using it .
    attribute(:fragment_size_required_from, :required =>true, :integer => true)
    attribute(:fragment_size_required_to, :required =>true, :integer =>true)

    attribute(:read_length, :integer => true, :required => true, :in => READ_LENGTHS)
  end

  def create_assets_for_multiplexing
    barcode = AssetBarcode.new_barcode
    # Needs a sample?
    puldown_mx_library = PulldownMultiplexedLibraryTube.create!(:name => "#{barcode}", :barcode => barcode)
    lane = Lane.create!(:name => puldown_mx_library.name)

    self.update_attributes!(:asset => puldown_mx_library, :target_asset =>lane)
  end

  class RequestOptionsValidator < DelegateValidation::Validator
    delegate_attribute :read_length, :to => :target, :type_cast => :to_i
    validates_inclusion_of :read_length, :in => SequencingRequest::READ_LENGTHS, :if => :read_length_needs_checking?

    delegate :fragment_size_required_from, :fragment_size_required_to, :to => :target
    validates_numericality_of :fragment_size_required_from, :integer_only => true, :greater_than => 0
    validates_numericality_of :fragment_size_required_to, :integer_only => true, :greater_than => 0
  end

  def self.delegate_validator
    SequencingRequest::RequestOptionsValidator
  end
end
