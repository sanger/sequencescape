module Admin
  module AccessioningToolsHelper
    def action_checklist_item(condition:, good:, bad:, action: nil)
      content_tag(:div) do
        icon = condition ? good_icon : bad_icon
        label = condition ? good : bad
        action_element = action_section(action)

        safe_join([icon, ' ', label, action_element])
      end
    end

    private

    def action_section(action)
      return unless action

      content_tag(:span, class: 'text-muted') do
        safe_join([' — ', action])
      end
    end

    def good_icon
      icon('fas', 'check', class: 'text-success')
    end

    def bad_icon
      icon('fas', 'xmark', class: 'text-danger')
    end
  end
end
