module MockAccession
  Response = Struct.new(:code, :body)

  def successful_accession_response
    Response.new(200,
      '<RECEIPT success="true"><SAMPLE accession="EGA00001000240" /></RECEIPT>')
  end

  def failed_accession_response
    Response.new(200,
      '<RECEIPT success="false"><ERROR>Error 1</ERROR><ERROR>Error 2</ERROR></RECEIPT>')
  end
end
