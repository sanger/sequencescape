class Event::SampleLogisticsQcEvent < Event
  def self.create_gel_qc_for_asset!(asset, result, user)
    if asset.is_a?(Well)
      gel_qc_message(asset, "Gel Analysed for well #{asset.id} with #{result}", 'gel_analysed', user)
    elsif asset.is_a?(Plate)
      gel_qc_message(asset, 'Gel Analysed', 'gel_analysed', user)
    end
  end

  def self.gel_qc_message(asset, message, family, user)
    create!(
      eventful: asset,
      message: message,
      content: Date.today.to_s,
      family: family,
      created_by: user ? user.login : nil
    )
  end

  def self.pico_qc_message(asset, message, family)
    create!(
      eventful: asset,
      message: message,
      content: Date.today.to_s,
      family: family
    )
  end

  def self.create_pico_result_for_asset!(asset, result)
    if asset.is_a?(Well)
      pico_qc_message(asset, "Pico result for well #{asset.id} with #{result}", 'pico_analysed')
    elsif asset.is_a?(Plate)
      pico_qc_message(asset, "Pico result for plate #{asset.barcode_number} with #{result}", 'pico_analysed')
    end
  end
end
