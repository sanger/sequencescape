# frozen_string_literal: true

module Api
  module V2
    module Aker
      # Endpoint to create Jobs inside Sequencescape from Aker
      class JobsController < ApplicationController
        before_action :login_required, except: [:create]
        skip_before_action :verify_authenticity_token

        def create
          jobs = params[:data]

          begin
            ActiveRecord::Base.transaction do
              jobs.each do |job|
                @job = ::Aker::Factories::Job.new(job[:attributes].permit!)
                if @job.valid?
                  @job.create
                else
                  raise "Job #{job.id} is not valid."
                end
              end
              render json: @job, status: :created
            end
          rescue => e
            render json: @job.errors, status: :unprocessable_entity
          end

        end
      end
    end
  end
end
