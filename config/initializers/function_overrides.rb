require 'uri'

module URI
  class << self
    def unescape(str)
      URI.decode_www_form_component(str)
    end
  end
end
