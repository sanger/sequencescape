# frozen_string_literal: true

module Api
  module V2
    module Aker
      # Endpoint to create Jobs inside Sequencescape from Aker
      class JobsController < ApplicationController
        before_action :login_required, except: [:create]
        skip_before_action :verify_authenticity_token

        def create
          ActiveRecord::Base.transaction do
            @msg = create_job_response(params)
            raise ActiveRecord::Rollback unless @msg[:status] == :created
          end
          render @msg
        rescue StandardError => e
          render json: e.message, status: :unprocessable_entity
        end

        private

        def create_job_response(params)
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
