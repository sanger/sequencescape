require 'xsd/qname'

# {urn:Barcode/Service}BarcodeLabelDTO
class BarcodeLabelDTO
  attr_accessor :barcode
  attr_accessor :desc
  attr_accessor :name
  attr_accessor :prefix
  attr_accessor :project
  attr_accessor :suffix

  def initialize(barcode = nil, desc = nil, name = nil, prefix = nil, project = nil, suffix = nil)
    @barcode = barcode
    @desc = desc
    @name = name
    @prefix = prefix
    @project = project
    @suffix = suffix
  end
end

# {urn:Barcode/Service}BarcodeDTO
class BarcodeDTO
  attr_accessor :check
  attr_accessor :number
  attr_accessor :process
  attr_accessor :type
  attr_accessor :whole

  def initialize(check = nil, number = nil, process = nil, type = nil, whole = nil)
    @check = check
    @number = number
    @process = process
    @type = type
    @whole = whole
  end
end

# {urn:Barcode/Service}ArrayOfBarcodeLabelDTO
class ArrayOfBarcodeLabelDTO < ::Array
end
