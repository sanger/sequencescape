# frozen_string_literal: true

module RemoteLinkPaginationHelper
  class LinkRenderer < BootstrapPagination::Rails
    def link(text, target, attributes = {})
      attributes['data-remote'] = true
      super
    end
  end
end
