# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

module DescriptorJavascriptHelper
  # The <tt>javascripts/descriptor.js</tt> needs a certain kind of setup to ensure that it behaves
  # properly and so this is what this method generates in the HTML.
  def descriptor_javascript_support(controller_name, model_name)
    javascript_include_tag('descriptors') <<
      javascript_tag("set_controller('#{controller_name}'); set_model('#{model_name}');") <<
      hidden_field_tag(:count, @count)
  end

  def link_to_add_descriptor(&block)
    link_to_with_onclick_only('addDescriptor();return false;', &block)
  end

  def link_to_remove_descriptor(index, &block)
    link_to_with_onclick_only("removeDescriptor(#{index});return false;", &block)
  end

  def link_to_add_asset(family, &block)
    link_to_with_onclick_only("addAsset('#{family.id}');return false;", &block)
  end

  def link_to_remove_asset(index, &block)
    link_to_with_onclick_only("removeAsset(#{index});return false;", &block)
  end

  def link_to_add_option(index, controller, model, &block)
    link_to_with_onclick_only("addOption(#{index},'#{controller}','#{model}');return false;", &block)
  end

  def link_to_remove_option(index, option, &block)
    link_to_with_onclick_only("removeOption(#{index},#{option});return false;", &block);
  end

private

  def link_to_with_onclick_only(on_click_code, &block)
    concat(
      content_tag(
        :a,
        capture(&block),
        href: 'javascript:void();',
        onClick: on_click_code
      )
    )
  end
end
