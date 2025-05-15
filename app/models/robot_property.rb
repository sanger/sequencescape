# frozen_string_literal: true
class RobotProperty < ApplicationRecord
  belongs_to :robot

  scope :beds, -> { where(name: nil) }

  def ean13_barcode
    if name.nil?
      str = Barcode.calculate_barcode('BD', value.to_i).to_s
      str.length == 12 ? "0#{str}" : str
    end
  end

  def human_barcode
    return nil unless name.nil?

    "BD#{value}#{Barcode.calculate_checksum('BD', value.to_i)}"
  end

  def barcode
    return nil unless name.nil?

    value.to_i
  end

  def sti_type
    self.class
  end
end
