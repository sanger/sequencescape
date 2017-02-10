# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2014,2015 Genome Research Ltd.

class NpgActions::AssetsController < ApplicationController
  before_action :login_required, except: [:pass, :fail]
  before_action :find_asset, only: [:pass, :fail]
  before_action :find_request, only: [:pass, :fail]
  before_action :npg_action_invalid?, only: [:pass, :fail]
  before_action :xml_valid?, only: [:pass, :fail]

  rescue_from(ActiveRecord::RecordNotFound, with: :rescue_error)

  XmlInvalid = Class.new(StandardError)
  rescue_from(XmlInvalid, with: :rescue_error)

  NPGActionInvalid = Class.new(StandardError)
  rescue_from(NPGActionInvalid, with: :rescue_error_internal_server_error)

  # this procedure build a procedure called "state". In this casa: pass and fail.
  def self.construct_action_for_qc_state(state)
    line = __LINE__ + 1
    class_eval(%Q{
      def #{state}
        begin
          ActiveRecord::Base.transaction do
            @asset.set_qc_state('#{state}ed')
            @asset.events.create_#{state}!(params[:qc_information][:message] || 'No reason given')
            request =  @asset.source_request

            batch = request.batch
            raise ActiveRecord::RecordNotFound, "Unable to find a batch for the Request" if (batch.nil?)

            message = "#{state}ed manual QC".capitalize
            EventSender.send_#{state}_event(request.id, "", message, "","npg", :need_to_know_exceptions => true)

            batch.npg_set_state   if ('#{state}' == 'pass')

          end
        end

        respond_to do |format|
          format.xml { render :file => 'assets/show'}
        end
      end
    }, __FILE__, line)
  end

  construct_action_for_qc_state('pass')
  construct_action_for_qc_state('fail')

  private

  def find_asset
    @asset ||= Asset.find(params[:asset_id])
  end

  def find_request
    @asset ||= Asset.find(params[:asset_id])
    if ((@asset.has_many_requests?) || (@asset.source_request.nil?))
      raise ActiveRecord::RecordNotFound, "Unable to find a request for Lane: #{params[:id]}"
    end
  end

  def xml_valid?
   raise XmlInvalid, 'XML invalid' if params[:qc_information].nil?
  end

  def npg_action_invalid?
   @asset ||= Asset.find(params[:asset_id])
   request = @asset.source_request
   npg_events = Event.npg_events(request.id)
   raise NPGActionInvalid, 'NPG user run this action. Please, contact USG' if npg_events.size > 0
  end

  def rescue_error(exception)
    respond_to do |format|
      format.xml { render xml: "<error><message>#{exception.message}</message></error>", status: '404' }
    end
  end

  def rescue_error_internal_server_error(exception)
    respond_to do |format|
      format.xml { render xml: "<error><message>#{exception.message}</message></error>", status: '500' }
    end
  end
end
