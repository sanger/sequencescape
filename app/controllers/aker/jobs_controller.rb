# frozen_string_literal: true

module Aker
  # Provide index and show actions to display jobs inside Sequencescapew, and start, complete and cancel
  # endpoints to change the status of the jobs from the inbox application
  class JobsController < ApplicationController
    before_action :set_job
    before_action :login_required, except: %i[start complete cancel show index]

    def index
      @jobs = Aker::Job.paginate(page: params[:page], per_page: 10).order(created_at: :desc)
    end

    def show
      recover_from_connection_refused do
        @aker_job =
          JSON.parse(
            RestClient::Request.execute(
              verify_ssl: false,
              method: :get,
              url: @job.aker_job_url.to_s,
              headers: {
                content_type: :json
              },
              proxy: nil
            ).body
          )[
            'job'
          ]
      end
    end

    def start
      recover_from_connection_refused do
        response =
          RestClient::Request.execute(
            verify_ssl: false,
            method: :put,
            url: "#{@job.aker_job_url}/start",
            headers: {
              content_type: :json
            },
            proxy: nil
          )

        render json: response.body, status: :ok
      end
    end

    def complete
      _finish_action("#{@job.aker_job_url}/complete")
    end

    def cancel
      _finish_action("#{@job.aker_job_url}/cancel")
    end

    private

    def _finish_action(url)
      recover_from_connection_refused do
        response =
          RestClient::Request.execute(
            verify_ssl: false,
            method: :put,
            url: url,
            payload: @job.finish_message.to_json,
            headers: {
              content_type: :json
            },
            proxy: nil
          )

        render json: response.body, status: :ok
      end
    end

    def recover_from_connection_refused
      yield
    rescue Errno::ECONNREFUSED
      render json: { error: 'Cannot connect with Aker Work orders service. Please contact the administrators' }
    rescue RestClient::NotFound
      render json: { error: 'The work order was not found in Aker Work orders service.' }
    rescue RestClient::InternalServerError
      render json: { error: 'There was a problem in the Aker Work orders service. Please contact the administrators' }
    end

    def set_job
      @job ||= Aker::Job.find_by(job_uuid: params[:id]) if params[:id]
    end
  end
end
