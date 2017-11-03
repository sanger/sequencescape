module Aker
  class WorkOrdersController < ApplicationController

    before_action :login_required, except: [:complete, :cancel, :show, :index]

    def index
      @work_orders = Aker::WorkOrder.all
    end

    def show
      @work_order = current_resource
      @aker_work_order = JSON.parse(RestClient::Request.execute(
        verify_ssl: false,
        method: :get,
        url: "#{Rails.configuration.aker['urls']['work_orders']}/work_orders/#{@work_order.aker_id}",
        headers: { content_type: :json, Accept: :json },
        proxy: nil
      ).body)['work_order']
    end

    def complete
      work_order = current_resource
      response = RestClient::Request.execute(
        verify_ssl: false,
        method: :post,
        url: "#{Rails.configuration.aker['urls']['work_orders']}/work_orders/#{work_order.aker_id}/complete",
        payload: { work_order: {work_order_id: work_order.aker_id, comment: params[:comment]} }.to_json,
        headers: { content_type: :json },
        proxy: nil
      )
      flash[:notice] = JSON.parse(response.body)['message']

      redirect_to aker_work_order_path(work_order)
    end

    def cancel
      work_order = current_resource
      response = RestClient::Request.execute(
        verify_ssl: false,
        method: :post,
        url: "#{Rails.configuration.aker['urls']['work_orders']}/work_orders/#{work_order.aker_id}/cancel",
        payload: { work_order: {work_order_id: work_order.aker_id, comment: params[:comment]} }.to_json, 
        headers: {content_type: :json},
        proxy: nil
      )
      flash[:notice] = JSON.parse(response.body)['message']
      
      redirect_to aker_work_order_path(work_order)
    end

    private

    def current_resource
      @current_resource ||= Aker::WorkOrder.find(params[:id]) if params[:id]
    end
  end
end