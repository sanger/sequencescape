# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2013,2015,2016 Genome Research Ltd.

class Event < ActiveRecord::Base
  include Api::EventIO::Extensions
  include Uuid::Uuidable

  self.per_page = 500
  belongs_to :eventful, polymorphic: true
  after_create :rescuing_update_request, unless: :need_to_know_exceptions?
  after_create :update_request,          if: :need_to_know_exceptions?

 scope :family_pass_and_fail, -> { where(family: ['pass', 'fail']).order('id DESC') }
 scope :npg_events, ->(*args) { where(created_by: 'npg', eventful_id: args[0]) }

  attr_writer :need_to_know_exceptions
  def need_to_know_exceptions?
    @need_to_know_exceptions
  end

  def request?
    eventful_type == 'Request' ? true : false
  end

  private

  include Event::AssetDescriptorUpdateEvent
  include Event::RequestDescriptorUpdateEvent

  def rescuing_update_request
    update_request
  end

  def update_request
    if request?
      request = eventful
      unless request.nil? or request.failed? or request.cancelled?
        if family == 'fail'
          request.fail!
        elsif family == 'pass' # && !request.project.nil?
          request.pass!
        end
      end
    end
  end
end
