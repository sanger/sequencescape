module PropertyHelper
  def help_text(label_text = nil, &block)
    content = capture(&block)
    return if content.blank?

    # TODO: This regexp isn't obvious until you stare at it for a while but:
    #   * The $1 is at least 20 characters long on match
    #   * $1 will end with a complete word (even if 20 characters is in the middle)
    #   * If there's no match then $1 is nil
    # Hence shortened_text is either nil or at least 20 characters
    shortened_text = (content =~ /^(.{20}\S*)\s\S/ and $1)

    if shortened_text.nil?
      concat(content)
    else
      concat(shortened_text)
      tooltip_id = "prop_#{ content.hash }_help"
      concat(label_tag("tooltip_content_#{tooltip_id}", label_text, :style => 'display:none;'))
      
      tooltip('...', :id => tooltip_id, &block)
    end
  end
end
