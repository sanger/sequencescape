module Accession

  require_relative "accession/core_extensions"
  require_relative "accession/contact"
  require_relative "accession/service"
  require_relative "accession/sample"
  require_relative "accession/tag"
  require_relative "accession/tag_list"
  require_relative "accession/submission"
  require_relative "accession/request"
  require_relative "accession/response"

  String.send(:include, CoreExtensions::String)

  CENTER_NAME = "SC".freeze
  XML_NAMESPACE = {'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance'}.freeze

end