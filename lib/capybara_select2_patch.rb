# frozen_string_literal: true

# Select2 breaks Capybara since select dropdowns are changed to span dropdowns.
# This patch identifies when Select2 is being used and changes the dropdown using Javascript instead.
module CapybaraSelect2Patch
  # Intercept the standard Capybara select method
  def select(*args, wait: 3, **kwargs)
    super(*args, **kwargs, wait:)
  rescue StandardError
    select_js(args[0], from: kwargs[:from])
  end

  private

  def select_js(option_text, from: nil)
    command = <<-JS
      let for_id = Array.from(document.getElementsByTagName('label')).filter(l => l.textContent == '#{from}')[0].htmlFor;
      let select = document.getElementById(for_id);
      select.selectedIndex = [...select.options].findIndex(option => option.text === '#{option_text}');
    JS
    execute_script(command)
  rescue Selenium::WebDriver::Error::JavascriptError => e
    raise $!, <<-ERROR_MESSAGE, $!.backtrace
    Cannot find option '#{option_text}' from select '#{from}'.
    See below for more info:
    #{e.backtrace[5..15].join("\n")}
    ERROR_MESSAGE
  end
end

Capybara::Node::Actions.prepend(CapybaraSelect2Patch) # where select is defined
