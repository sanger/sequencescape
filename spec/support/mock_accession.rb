# frozen_string_literal: true

module MockAccession
  Response = Struct.new(:code, :body)

  def successful_study_accession_response
    Response.new(200, '<RECEIPT success="true"><STUDY accession="EGA00002000345" /></RECEIPT>')
  end

  def successful_dac_policy_accession_response
    Response.new(200, <<~XML)
      <RECEIPT success="true">
        <DAC accession="EGAD0001000234" />
        <POLICY accession="EGAP0001000234" />
      </RECEIPT>
    XML
  end

  def failed_accession_response
    Response.new(200, <<~XML)
      <RECEIPT receiptDate="2014-12-02T16:06:20.871Z" success="false">
        <MESSAGES>
          <ERROR>Error 1</ERROR>
          <ERROR>Error 2</ERROR>
        </MESSAGES>
      </RECEIPT>
    XML
  end

  module_function :successful_study_accession_response, :failed_accession_response
end
