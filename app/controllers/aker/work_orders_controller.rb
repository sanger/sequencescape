module Aker
  class WorkOrdersController < ApplicationController
    before_action :login_required, except: [:complete, :cancel, :show, :index]

    def index
      @work_orders = Aker::WorkOrder.paginate(page: params[:page], per_page: 10).order(created_at: :desc)
    end

    def show
      @work_order = current_resource
      recover_from_connection_refused do
        @aker_work_order = JSON.parse(RestClient::Request.execute(
          verify_ssl: false,
          method: :get,
          url: "#{Rails.configuration.aker['urls']['work_orders']}/work_orders/#{@work_order.aker_id}",
          headers: { content_type: :json, Accept: :json },
          proxy: nil
        ).body)['work_order']
      end
    end

    def complete
      work_order = current_resource
      recover_from_connection_refused do
        response = RestClient::Request.execute(
          verify_ssl: false,
          method: :post,
          url: "#{Rails.configuration.aker['urls']['work_orders']}/work_orders/#{work_order.aker_id}/complete",
          payload: { work_order: { work_order_id: work_order.aker_id, comment: params[:comment] } }.to_json,
          headers: { content_type: :json },
          proxy: nil
        )
        flash[:notice] = JSON.parse(response.body)['message']

        redirect_to aker_work_order_path(work_order)
      end
    end

    def cancel
      work_order = current_resource
      recover_from_connection_refused do
        response = RestClient::Request.execute(
          verify_ssl: false,
          method: :post,
          url: "#{Rails.configuration.aker['urls']['work_orders']}/work_orders/#{work_order.aker_id}/cancel",
          payload: { work_order: { work_order_id: work_order.aker_id, comment: params[:comment] } }.to_json,
          headers: { content_type: :json },
          proxy: nil
        )
        flash[:notice] = JSON.parse(response.body)['message']

        redirect_to aker_work_order_path(work_order)
      end
    end

    private

    def recover_from_connection_refused
      yield
    rescue Errno::ECONNREFUSED
      flash[:error] = 'Cannot connect with Aker Work orders service. Please contact the administrators'
      redirect_to aker_work_orders_path
    rescue RestClient::NotFound
      flash[:error] = 'The work order was not found in Aker Work orders service.'
      redirect_to aker_work_orders_path
    rescue RestClient::InternalServerError
      flash[:error] = 'There was a problem in the Aker Work orders service. Please contact the administrators'
      redirect_to aker_work_orders_path
    end

    def current_resource
      @current_resource ||= Aker::WorkOrder.find(params[:id]) if params[:id]
    end
  end
end
