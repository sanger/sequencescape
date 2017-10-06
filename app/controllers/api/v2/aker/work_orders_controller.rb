# frozen_string_literal: true

module Api
  module V2
    module Aker
      class WorkOrdersController < ApplicationController
        before_action :login_required, except: [:create]

        def create
          @work_order = ::Aker::Factories::WorkOrder.new(params[:work_order].permit!)
          
          if @work_order.valid?

            @work_order.create
            render json: @work_order, status: :created
          else
            render json: @work_order.errors, status: :unprocessable_entity
          end
        end
      end
    end
  end
end
