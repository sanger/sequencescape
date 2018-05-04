# frozen_string_literal: true

module Aker
  # Provide index and show actions to display jobs inside Sequencescapew, and start, complete and cancel
  # endpoints to change the status of the jobs from the inbox application
  class JobsController < ApplicationController
    before_action :login_required, except: %i[start complete cancel show index]

    def index
      @jobs = Aker::Job.paginate(page: params[:page], per_page: 10).order(created_at: :desc)
    end

    def show
      @job = current_resource
      recover_from_connection_refused do
        @aker_job = JSON.parse(RestClient::Request.execute(
          verify_ssl: false,
          method: :get,
          url: "#{Rails.configuration.aker['urls']['work_orders']}/jobs/#{@job.aker_job_id}",
          headers: { content_type: :json, Accept: :json },
          proxy: nil
        ).body)['job']
      end
    end

    def start
      job = current_resource
      recover_from_connection_refused do
        response = RestClient::Request.execute(
          verify_ssl: false,
          method: :put,
          url: "#{Rails.configuration.aker['urls']['work_orders']}/jobs/#{job.aker_job_id}/start",
          headers: { content_type: :json },
          proxy: nil
        )

        render json: response.body, status: :ok
      end
    end

    def complete
      job = current_resource
      recover_from_connection_refused do
        response = RestClient::Request.execute(
          verify_ssl: false,
          method: :put,
          url: "#{Rails.configuration.aker['urls']['work_orders']}/jobs/#{job.aker_job_id}/complete",
          payload: { job: { job_id: job.aker_job_id, comment: params[:comment] } }.to_json,
          headers: { content_type: :json },
          proxy: nil
        )

        render json: response.body, status: :ok
      end
    end

    def cancel
      job = current_resource
      recover_from_connection_refused do
        response = RestClient::Request.execute(
          verify_ssl: false,
          method: :put,
          url: "#{Rails.configuration.aker['urls']['work_orders']}/jobs/#{job.aker_job_id}/cancel",
          payload: { job: { job_id: job.aker_job_id, comment: params[:comment] } }.to_json,
          headers: { content_type: :json },
          proxy: nil
        )

        render json: response.body, status: :ok
      end
    end

    private

    def recover_from_connection_refused
      yield
    rescue Errno::ECONNREFUSED
      flash[:error] = 'Cannot connect with Aker Work orders service. Please contact the administrators'
      redirect_to aker_jobs_path
    rescue RestClient::NotFound
      flash[:error] = 'The work order was not found in Aker Work orders service.'
      redirect_to aker_jobs_path
    rescue RestClient::InternalServerError
      flash[:error] = 'There was a problem in the Aker Work orders service. Please contact the administrators'
      redirect_to aker_jobs_path
    end

    def current_resource
      @current_resource ||= Aker::Job.find_by(aker_job_id: params[:id]) if params[:id]
    end
  end
end
