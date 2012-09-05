class Event < ActiveRecord::Base
  include Api::EventIO::Extensions
  include Uuid::Uuidable
  cattr_reader :per_page
  @@per_page = 500
  belongs_to :eventful, :polymorphic => true
  after_create :rescuing_update_request, :unless => :need_to_know_exceptions?
  after_create :update_request,          :if     => :need_to_know_exceptions?

  named_scope :family_pass_and_fail, :conditions => {:family =>  ["pass", "fail"]}, :order => 'id DESC'
  named_scope :npg_events, lambda { |*args| {:conditions => ["created_by='npg' and eventful_id = ? ", args[0]] }}

  attr_writer :need_to_know_exceptions
  def need_to_know_exceptions?
    @need_to_know_exceptions
  end

  def request?
    self.eventful_type == "Request" ? true : false
  end

  private

  include Event::AssetDescriptorUpdateEvent
  include Event::RequestDescriptorUpdateEvent

  def rescuing_update_request
    update_request
  rescue BillingException::DuplicateCharge => exception
    # We can ignore this here
  end

  def update_request
    if self.request?
      request = self.eventful
      unless request.nil? or request.failed? or request.cancelled?
        if self.family == "fail"
          if self.descriptor_key == "library_creation_complete" or self.descriptor_key == "multiplexed_library_creation"
            request.state = "failed"
            request.save
            BillingEvent.generate_fail_event(request)
          else
            request.fail!
            unless request.asset.resource
              BillingEvent.generate_fail_event(request)
            end
          end
        elsif self.family == "pass"# && !request.project.nil?
          request.pass!
          unless request.asset.resource
            BillingEvent.generate_pass_event(request)
          end
        end
      end
    end
  end
end
