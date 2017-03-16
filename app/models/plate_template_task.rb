# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

class PlateTemplateTask < Task
  include Tasks::PlatePurposeBehavior

  class PlateTemplateData < Task::RenderElement
    attr_reader :testing
    alias_attribute :well, :asset

    def initialize(request)
      super(request)
      # get all requests
      # self.requests
      # populate plates from Template
      # display plates
    end
  end # class PlateTemplateData

  def create_render_element(request)
    request.asset && PlateTemplateData.new(request)
  end

  def partial
    'plate_template_batches'
  end

  def render_task(workflow, params)
    super
    workflow.render_plate_template_task(self, params)
  end

  def do_task(workflow, params)
    workflow.do_plate_template_task(self, params)
  end
end
