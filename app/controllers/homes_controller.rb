# frozen_string_literal: true
class HomesController < ApplicationController
  before_action :login_required

  def show # rubocop:todo Metrics/AbcSize
    @links = configatron.fetch(:external_applications, [])
    @pipelines = current_user.pipelines.active
    @latest_batches = current_user.batches.latest_first.limit(10).includes(:pipeline)
    @assigned_batches = current_user.batches.latest_first.where('assignee_id != user_id').limit(10).includes(:pipeline)
    @submissions = current_user.submissions.latest_first.limit(10)
    @studies = current_user.interesting_studies.newest_first.limit(10)
  end
end
