# frozen_string_literal: true

# Automatically add a nonce to the Vite external resource tags for use with the Content Security Policy.
#
# The content security policy itself is defined in config/initializers/content_security_policy.rb
module ViteRailsNoncePatch
  def vite_javascript_tag(*names, **options)
    options[:nonce] = true unless options.key?(:nonce)

    super
  end

  def vite_stylesheet_tag(*names, **options)
    options[:nonce] = true unless options.key?(:nonce)

    super
  end
end

ViteRails::TagHelpers.prepend(ViteRailsNoncePatch)
