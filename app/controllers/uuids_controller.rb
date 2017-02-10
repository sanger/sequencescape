# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2016 Genome Research Ltd.

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
