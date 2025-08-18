# frozen_string_literal: true

module MockAccession
  Response = Struct.new(:code, :body)

  # for samples
  def successful_accession_response
    Response.new(200, '<RECEIPT success="true"><SAMPLE accession="EGA00001000240" /></RECEIPT>')
  end

  def successful_study_accession_response
    Response.new(200, '<RECEIPT success="true"><STUDY accession="EGA00002000345" /></RECEIPT>')
  end

  def failed_accession_response
    Response.new(200, '<RECEIPT success="false"><ERROR>Error 1</ERROR><ERROR>Error 2</ERROR></RECEIPT>')
  end

  module_function :successful_accession_response, :successful_study_accession_response, :failed_accession_response
end
