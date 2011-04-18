class EventSender

  # format message expected output
  # <?xml version='1.0'?>
  # <event>
  # <message>win</message>
  # <eventful_id>123</eventful_id>
  # <eventful_type>Request</eventful_type>
  # <descriptor_key>failure</descriptor_key>
  # <content>fail</content>
  # <family>fail</family>
  # <identifier>123</identifier>
  # </event>
  def self.format_message(hash)
    doc = hash.to_xml(:root => "event", :skip_types => true)
    doc.to_s.gsub!('-', '_').gsub!('UTF_8', 'UTF-8')
  end

  def self.send_fail_event(request_id, reason, comment, batch_id, user=nil, options = nil)
    hash = { :eventful_id => request_id, :eventful_type => 'Request', :family => "fail", :content => reason, :message => comment, :identifier => batch_id, :key => "failure", :created_by => user }
    self.publishing_to_queue(hash.merge(options || {}))
  end

  def self.send_cancel_event(request_id, reason, comment, options = nil)
    hash = { :eventful_id => request_id, :eventful_type => 'Request', :family => "cancel", :content => reason, :message => comment, :identifier => request_id, :key => "cancel" }
    self.publishing_to_queue(hash.merge(options || {}))
  end

  def self.send_pass_event(request_id, reason, comment, batch_id, user=nil, options = nil)
    hash = { :eventful_id => request_id, :eventful_type => 'Request', :family => "pass", :content => reason, :message => comment, :identifier => batch_id, :key => "pass", :created_by => user }
    self.publishing_to_queue(hash.merge(options || {}))
  end

  def self.send_request_update(request_id, family, message, options = nil)
    hash = { :eventful_id => request_id, :eventful_type => 'Request', :family => family, :message => message }
    self.publishing_to_queue(hash.merge(options || {}))
  end

  private

  def self.publishing_to_queue(hash = {})
    hash.delete(:key)
    Event.create(hash)
  end

end
