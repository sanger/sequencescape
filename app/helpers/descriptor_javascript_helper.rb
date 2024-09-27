# frozen_string_literal: true
module DescriptorJavascriptHelper
  def link_to_remove_asset(index, &)
    link_to_with_onclick_only("removeAsset(#{index});return false;", &)
  end

  private

  def link_to_with_onclick_only(on_click_code, &)
    concat(tag.a(capture(&), href: 'javascript:void();', onClick: on_click_code))
  end
end
