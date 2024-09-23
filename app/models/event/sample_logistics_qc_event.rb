# frozen_string_literal: true
class Event::SampleLogisticsQcEvent < Event
  def self.create_gel_qc_for_asset!(asset, result, user)
    case asset
    when Well
      gel_qc_message(asset, "Gel Analysed for well #{asset.id} with #{result}", 'gel_analysed', user)
    when Plate
      gel_qc_message(asset, 'Gel Analysed', 'gel_analysed', user)
    end
  end

  def self.gel_qc_message(asset, message, family, user)
    create!(eventful: asset, message:, content: Date.today.to_s, family:, created_by: user ? user.login : nil)
  end
end
