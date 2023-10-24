# frozen_string_literal: true
class UuidsController < ApplicationController
  def show
    uuid = Uuid.find_by!(external_id: params[:id])

    # We need to override the automatic path finding for
    # a resource here as our controllers are a little inconsistent
    # and assets especially end up getting redirected to undesired
    # locations. This line basically coerces a resource to its
    # base class, ensuring it ends up at the correct controller.
    redirect_to(uuid.resource.becomes uuid.resource.class.base_class)
  end
end
