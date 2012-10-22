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
      @testing = "testing"

    end


  end # class PlateTemplateData

  def create_render_element(request)
    request.asset && PlateTemplateData.new(request)
  end

  def partial
    "plate_template_batches"
  end

  def render_task(workflow, params)
    super
    workflow.render_plate_template_task(self, params)
  end

  def do_task(workflow, params)
    workflow.do_plate_template_task(self, params)
  end


end
