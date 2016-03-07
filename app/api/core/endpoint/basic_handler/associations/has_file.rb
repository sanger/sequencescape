#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
module Core::Endpoint::BasicHandler::Associations::HasFile
  def has_file(options)
    ::Api::EndpointHandler.register_mimetype(options[:content_type])
    @supported_types ||= {}
    @supported_types[options[:content_type]]= options[:as]||:retrieve_file
  end

  def content_type(content_type)
    return nil unless @supported_types.present?
    @supported_types[content_type]
  end

  def file_through(content_types)
    content_type(content_types.detect do |ct|
      content_type(ct)
    end)
  end

end
