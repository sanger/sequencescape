
class Api::EventsController < Api::BaseController
  self.model_class = Event

  before_action :prepare_object, only: [:show]
  before_action :prepare_list_context, only: [:index]

  private

  def prepare_list_context
    @context = ::Event.including_associations_for_json
  end
end
