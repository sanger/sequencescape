# frozen_string_literal: true
module Core::Endpoint::BasicHandler::Associations::HasFile
  def has_file(options)
    ::Api::EndpointHandler.register_mimetype(options[:content_type])
    @supported_types ||= {}
    @supported_types[options[:content_type]] = options[:as] || :retrieve_file
  end

  def content_type(content_type)
    return nil if @supported_types.blank?

    @supported_types[content_type]
  end

  def file_through(content_types)
    content_type(content_types.detect { |ct| content_type(ct) })
  end
end
