module Tasks::PlateTemplateHandler
  def render_plate_template_task(task, params)
    @plate_templates = PlateTemplate.all
    @robots = Robot.all
  end

  def do_plate_template_task(task, params)
    return true if params[:file].blank?

    if params[:plate_template].blank?
      plate_size = 96
    else
      plate_size = PlateTemplate.find(params[:plate_template]["0"].to_i).size
    end

    parsed_plate_details = CherrypickTask.parse_uploaded_spreadsheet_layout(params[:file],plate_size)
    @spreadsheet_layout = CherrypickTask.map_parsed_spreadsheet_to_plate(parsed_plate_details,@batch,plate_size)

    true
  end
end
