# frozen_string_literal: true

module RemoteLinkPaginationHelper
  class LinkRenderer < BootstrapPagination::Rails
    def link(text, target, attributes = {})
      attributes['data-remote'] = true
      attributes['data-update'] ||= @options[:update]
      attributes['data-throbber'] ||= @options[:throbber]
      attributes['data-failure'] ||= @options[:failure]
      attributes['data-keep-html'] ||= @options[:keep_html]
      super
    end
  end
end
