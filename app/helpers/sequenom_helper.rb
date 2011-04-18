module SequenomHelper
  def dropdown_for_steps(field_name)
    select_tag(field_name, options_for_select(SequenomController::STEPS.map(&:name), :select => SequenomController::STEPS.first.name))
  end
end
