class SequencingRequest < Request

  extend Request::AccessioningRequired

  has_metadata :as => Request  do
    #redundant with library creation , but THEY are using it .
    attribute(:fragment_size_required_from, :required =>true, :integer => true)
    attribute(:fragment_size_required_to, :required =>true, :integer =>true)

    attribute(:read_length, { :integer => true, :from => :valid_read_lengths, :required => true })
  end

  SequencingRequest::Metadata.class_eval do
    def valid_read_lengths
      owner.request_type.request_type_validators.find(:first,:conditions=>{:request_option=>'read_length'}).try(:valid_options)||
      raise(StandardError, "No read lengths specified for #{owner.request_type.name}")
    end
  end

  before_validation :clear_cross_projects
  def clear_cross_projects
    self.initial_project = nil if submission.try(:cross_project?)
    self.initial_study   = nil if submission.try(:cross_study?)
  end
  private :clear_cross_projects

  def create_assets_for_multiplexing
    barcode = AssetBarcode.new_barcode
    # Needs a sample?
    puldown_mx_library = PulldownMultiplexedLibraryTube.create!(:name => "#{barcode}", :barcode => barcode)
    lane = Lane.create!(:name => puldown_mx_library.name)

    self.update_attributes!(:asset => puldown_mx_library, :target_asset =>lane)
  end

  class RequestOptionsValidator < DelegateValidation::Validator
    delegate :fragment_size_required_from, :fragment_size_required_to, :to => :target
    validates_numericality_of :fragment_size_required_from, :integer_only => true, :greater_than => 0
    validates_numericality_of :fragment_size_required_to, :integer_only => true, :greater_than => 0
  end

  def order=(_)
    # Do nothing
  end

  def self.delegate_validator
    SequencingRequest::RequestOptionsValidator
  end
end
