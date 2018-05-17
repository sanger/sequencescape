# frozen_string_literal: true

module Api
  module V2
    module Aker
      # Endpoint to create Jobs inside Sequencescape from Aker
      class JobsController < ApplicationController
        before_action :login_required, except: [:create]
        skip_before_action :verify_authenticity_token

        def create
          @job = ::Aker::Factories::Job.new(params[:job].permit!)
          if @job.valid?

            @job.create
            render json: @job, status: :created
          else
            render json: @job.errors, status: :unprocessable_entity
          end
        end
      end
    end
  end
end
