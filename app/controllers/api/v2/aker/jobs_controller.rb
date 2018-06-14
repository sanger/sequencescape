# frozen_string_literal: true

module Api
  module V2
    module Aker
      # Endpoint to create Jobs inside Sequencescape from Aker
      class JobsController < ApplicationController
        before_action :login_required, except: [:create]
        skip_before_action :verify_authenticity_token

        def create
          param_jobs = params[:data]
          @jobs = []
          begin
            ActiveRecord::Base.transaction do
              @jobs = param_jobs.map do |param_job|
                job = ::Aker::Factories::Job.new(param_job[:attributes].permit!)
              end
              if @jobs.all?(&:valid?)
                @jobs.each(&:create)
                render json: @jobs, status: :created
              else
                render json: @jobs.map(&:errors), status: :unprocessable_entity
              end
            end
          rescue StandardError => e
            render json: e.message, status: :unprocessable_entity
          end
        end
      end
    end
  end
end
