# frozen_string_literal: true
module PrototypeReplacementHelper # rubocop:todo Style/Documentation
  def remote_button(label, url, data, html_options = {})
    form_tag url, remote: true, data: data, class: 'remote-form' do
      submit_tag(label, html_options)
    end
  end
end
