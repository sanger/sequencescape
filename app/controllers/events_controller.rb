class EventsController < ApplicationController

  def new
    @event = Event.new
  end

  def create
    # Compatible with NPG
    params[:event].delete(:key)
    @event = Event.create(params[:event])

    unless @event.eventful.nil?
      @event.eventful.save
    end

    respond_to do |format|
      format.xml  { render :xml => @event.to_xml }
      format.json  { render :json => @event.to_json }
    end
  end

end
