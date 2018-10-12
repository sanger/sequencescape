class MiSeqSequencingRequest < SequencingRequest
  include Request::CustomerResponsibility

  def flowcell_identifier
    'Cartridge barcode'
  end
end
