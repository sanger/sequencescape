# rubocop:disable all
# We've switched to the npm package for most out requirements, but still need the helpers at runtime
# We import them here to allow us to remove font-awesome-sass as a dependency
# Imported from https://github.com/FortAwesome/font-awesome-sass
# Original source: https://github.com/FortAwesome/font-awesome-sass/blob/master/lib/font_awesome/sass/rails/helpers.rb
# Reproduced under original license: https://github.com/FortAwesome/font-awesome-sass/blob/master/LICENSE.txt

# Move fontawesomeinto default gemset and remove once off metal
module FontawesomeHelper
  def icon(style, name, text = nil, html_options = {})
    text, html_options = nil, text if text.is_a?(Hash)

    content_class = +"#{style} fa-#{name}"
    content_class << " #{html_options[:class]}" if html_options.key?(:class)
    html_options[:class] = content_class

    html = content_tag(:i, nil, html_options)
    html << ' ' << text.to_s unless text.blank?
    html
  end
end
# rubocop:enable all
