# frozen_string_literal: true

require 'base64'

# Helper for capybara tests to log state on failed tests
module CapybaraFailureLogger
  #
  # Call on test failure to log:
  # - The HTML of the page
  # - The content of the JS error console (if possible)
  # - An image of the failed page (if possible)
  #
  # @param name [String] The name of the test, forms a basis of the filename
  # @param page [Capybara::Session] The Capybara session object (other exposed as page)
  # @yield [String] Yields strings to be logged
  #
  # @return [void]
  #
  def self.log_failure(name, page, &block)
    block ||= method(:puts)

    log_screenshot(name, page, &block)
    log_html(name, page, &block)
    log_js(name, page, &block)
  end

  def self.log_screenshot(name, page, &block)
    return unless page.respond_to?(:save_screenshot)

    page.save_screenshot("#{name}.png")
    filename = "#{Capybara.save_path}/#{name}.png"
    block.call "📸 Screenshot saved to #{filename}"
    output_image(filename, &block)
  rescue Capybara::NotSupportedByDriverError
    block.call 'Could not save screenshot - Unsupported by this webdriver'
  end

  def self.log_html(name, page, &block)
    return unless page.respond_to?(:save_page)

    page.save_page("#{name}.html")
    block.call "📐 HTML saved to #{Capybara.save_path}/#{name}.html"
  end

  def self.log_js(_name, page, &block)
    return unless page.driver.browser.respond_to?(:manage)

    errors = page.driver.browser.manage.logs.get(:browser)
    block.call '== JS errors ============'
    errors.each { |jserror| block.call jserror.message }
    block.call '========================='
  end

  def self.output_image(filename, &block)
    return unless ENV['TERM_PROGRAM'] == 'iTerm.app'

    case ENV['INLINE_ERROR_SCREENSHOTS']
    when 'enabled'
      encoded_image = Base64.encode64(File.read(filename))
      name = Base64.encode64(filename)
      block.call "\e]1337;File=inline=1;name=#{name}:#{encoded_image}\a"
    when nil
      block.call 'Want inline images? Set the env INLINE_ERROR_SCREENSHOTS to enabled,'
      block.call 'or set INLINE_ERROR_SCREENSHOTS to anything else to disable this message.'
    end
  end
end
