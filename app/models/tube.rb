class Tube < Aliquot::Receptacle
  include LocationAssociation::Locatable
  include Barcode::Barcodeable
  include Tag::Associations
  include Asset::Ownership::Unowned

  named_scope :include_scanned_into_lab_event, :include => :scanned_into_lab_event

  # Base class for the all tube purposes
  class Purpose < ::Purpose
    # TODO: change to purpose_id
    has_many :tubes, :foreign_key => :plate_purpose_id

    def default_state(_)
      self[:default_state]
    end

    def created_with_request_options(tube)
      tube.parents.first
    end

    def create!(*args, &block)
      target_class.create!(*args, &block).tap { |t| tubes << t }
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
end
