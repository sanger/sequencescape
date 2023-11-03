# frozen_string_literal: true
module DescriptorJavascriptHelper
  def link_to_remove_asset(index, &block)
    link_to_with_onclick_only("removeAsset(#{index});return false;", &block)
  end

  private

  def link_to_with_onclick_only(on_click_code, &block)
    concat(tag.a(capture(&block), href: 'javascript:void();', onClick: on_click_code))
  end
end
