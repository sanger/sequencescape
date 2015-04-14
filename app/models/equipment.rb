class Equipment < ActiveRecord::Base
  attr_reader :name, :type, :barcode, :prefix
  before_create :generate_barcode

  def generate_barcode
    @prefix = 'XX' if @prefix.nil?
    debugger
    @barcode = Barcode.calculate_barcode(@prefix, @id)
  end

  def print
  end
end
