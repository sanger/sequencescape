class Tube < Aliquot::Receptacle
  include LocationAssociation::Locatable
  include Barcode::Barcodeable
  include ModelExtensions::Tube
  include Tag::Associations
  include Asset::Ownership::Unowned
  include Transfer::Associations
  include Transfer::State::TubeState

  # Transfer requests into a tube are direct requests where the tube is the target.
  def transfer_requests
    requests_as_target.where_is_a?(TransferRequest).all
  end

  named_scope :include_scanned_into_lab_event, :include => :scanned_into_lab_event

  named_scope :with_purpose, lambda { |*purposes|
    { :conditions => { :plate_purpose_id => purposes.flatten.map(&:id) } }
  }

  # Base class for the all tube purposes
  class Purpose < ::Purpose
    # TODO: change to purpose_id
    has_many :tubes, :foreign_key => :plate_purpose_id

    def default_state(_)
      self[:default_state]
    end

    def created_with_request_options(tube)
      tube.creation_request.try(:request_options_for_creation) || {}
    end

    def create!(*args, &block)
      target_class.create_with_barcode!(*args, &block).tap { |t| tubes << t }
    end

    # Define some simple helper methods
    class << self
      [ 'stock', 'standard' ].each do |purpose_type|
        [ 'sample', 'library', 'MX' ].each do |tube_type|
          name = "#{purpose_type} #{tube_type}"

          line = __LINE__ + 1
          class_eval(%Q{
            def #{name.downcase.gsub(/\W+/, '_')}_tube
              @#{name.downcase.gsub(/\W+/, '_')}_tube ||= find_by_name('#{name.humanize}') or raise "Cannot find #{name} tube"
            end
          }, __FILE__, line)
        end
      end
    end
  end

  class StockMx < Tube::Purpose
    def transition_to(tube, state, _ = nil)
      tube.requests_as_target.open.each do |request|
        request.transition_to(state)
      end
    end
  end

  class StandardMx < Tube::Purpose
    def created_with_request_options(tube)
      tube.parent.created_with_request_options
    end

    # Transitioning an MX library tube to a state involves updating the state of the transfer requests.  If the
    # state is anything but "started" or "pending" then the pulldown library creation request should also be
    # set to the same state
    def transition_to(tube, state, _ = nil)
      update_all_requests = ![ 'started', 'pending' ].include?(state)
      tube.requests_as_target.open.for_billing.each do |request|
        request.transition_to(state) if update_all_requests or request.is_a?(TransferRequest)
      end
    end
  end

  def self.delegate_to_purpose(*methods)
    methods.each do |method|
      class_eval(%Q{def #{method}(*args, &block) ; purpose.#{method}(self, *args, &block) ; end})
    end
  end

  # TODO: change column name to account for purpose, not plate_purpose!
  belongs_to :purpose, :class_name => 'Tube::Purpose', :foreign_key => :plate_purpose_id
  delegate_to_purpose(:transition_to, :created_with_request_options, :pool_id, :name_for_child_tube)
  delegate :barcode_type, :to => :purpose

  def name_for_label
    (primary_aliquot.nil? or primary_aliquot.sample.sanger_sample_id.blank?) ? self.name : primary_aliquot.sample.shorten_sanger_sample_id
  end

  def transfer_request_type_from(source)
    purpose.transfer_request_type_from(source.purpose)
  end

  def self.create_with_barcode!(*args, &block)
    attributes = args.extract_options!
    barcode    = args.first || attributes[:barcode]
    raise "Barcode: #{barcode} already used!" if barcode.present? and find_by_barcode(barcode).present?
    barcode  ||= AssetBarcode.new_barcode
    create!(attributes.merge(:barcode => barcode), &block)
  end
end
