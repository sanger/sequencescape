# frozen_string_literal: true

# Select2 breaks Capybara since select dropdowns are changed to span dropdowns.
# This patch identifies when Select2 is being used and changes the dropdown using Javascript instead.
module CapybaraSelect2Patch
  def select_js(option_text, from: nil)
    begin
      command = <<-JS
      let for_id = Array.from(document.getElementsByTagName('label')).filter(l => l.textContent == '#{from}')[0].htmlFor;
      let select = document.getElementById(for_id);
      select.selectedIndex = [...select.options].findIndex(option => option.text === '#{option_text}');
    JS
      page.execute_script(command)
    rescue StandardError
      binding.pry # TODO: remove after initial debugging is completed and all tests pass
    end
  end
end

Capybara::Node::Base.prepend(CapybaraSelect2Patch)
