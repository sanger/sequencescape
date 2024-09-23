# frozen_string_literal: true
module PrototypeReplacementHelper
  def remote_button(label, url, data, html_options = {})
    form_tag url, remote: true, data:, class: 'remote-form' do
      submit_tag(label, html_options)
    end
  end
end
