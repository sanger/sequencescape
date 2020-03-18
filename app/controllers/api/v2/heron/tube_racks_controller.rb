# frozen_string_literal: true

module Api
  module V2
    module Heron
      # Endpoint to create TubeRacks inside Sequencescape for Heron
      class TubeRacksController < ApplicationController
        before_action :login_required, except: [:create]
        skip_before_action :verify_authenticity_token

        def create
          return render json: {}, status: :created if params[:data][:tube_rack]
          render json: {}, status: :unprocessable_entity
        #  debugger
        #   return render json: {}, status: :created if params[:data][:tube_rack]
        #   ActiveRecord::Base.transaction do
        #     @msg = create_tube_rack_response(params)
        #     raise ActiveRecord::Rollback unless @msg[:status] == :created
        #   end
        #   render @msg
        # rescue StandardError => e
        #   render json: e.message, status: :unprocessable_entity
        end

        private

        def create_tube_rack_response(params)
          params[:data][:tube_rack]

          params[:data].each_with_object(json: [], status: :created) do |param_job, response|
            job = ::Aker::Factories::Job.new(param_job[:attributes].permit!)
            return { json: job.errors, status: :unprocessable_entity } unless job.valid?

            response[:json].push(job.create)
          end
        end
      end
    end
  end
end
