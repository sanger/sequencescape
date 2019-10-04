# Included in {Stamp}
# Handles the translation of V1 API input to more standard rails attributes
module ModelExtensions::Stamp
  def stamp_details=(details)
    stamp_qcables.build(details.map { |d| locate_qcable(d) })
  end

  private

  def locate_qcable(d)
    d['qcable'] = Uuid.find_by(external_id: d['qcable']).resource
    d
  end
end
