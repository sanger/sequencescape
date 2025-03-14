# frozen_string_literal: true

module SelectHelper
  # A helper to select option boxes using Javascript to get around Select2
  # incompatibilities with Capybara and Selenium.
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
