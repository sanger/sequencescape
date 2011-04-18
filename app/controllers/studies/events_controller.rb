class Studies::EventsController < ApplicationController

  def index
    @study = Study.find(params[:study_id])
    @events = @study.events.all(:order => "created_at ASC")
  end
end
