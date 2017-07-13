module Aker
  class WorkOrdersController < ApplicationController

    before_action :login_required, except: [:complete, :cancel, :show, :index]

    def index
      @work_orders = WorkOrder.all
    end

    def show
      @work_order = current_resource
      @aker_work_order = RestClient.get("#{Rails.configuration.aker['urls']['work_orders']}/work_orders/#{@work_order.aker_id}")['work_order']
    end

    def complete
      work_order = current_resource
      response = RestClient.post("#{Rails.configuration.aker['urls']['work_orders']}/work_orders/#{work_order.aker_id}/complete", {work_order: {id: work_order.aker_id, comment: params[:comment]}}, {content_type: :json})
      render json: response
    end

    def cancel
      work_order = current_resource
      response = RestClient.post("#{Rails.configuration.aker['urls']['work_orders']}/work_orders/#{work_order.aker_id}/cancel", {work_order: {id: work_order.aker_id, comment: params[:comment]}}, {content_type: :json})
      render json: response
    end

    private

    def current_resource
      @current_resource ||= WorkOrder.find(params[:id]) if params[:id]
    end
  end
end