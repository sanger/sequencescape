# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2014,2015,2016 Genome Research Ltd.

class Barcode
  # Anything that has a barcode is considered barcodeable.
  module Barcodeable
    def self.included(base)
      base.class_eval do
        before_create :set_default_prefix
        class_attribute :prefix
        self.prefix = 'NT'

        if ActiveRecord::Base.observers.include?(:amqp_observer)
          after_save :broadcast_barcode, if: :barcode_changed?
        end
      end
    end

    def generate_barcode
      self.barcode = AssetBarcode.new_barcode
    end

    def broadcast_barcode
      AmqpObserver.instance << Messenger.new(template: 'BarcodeIO', root: 'barcode', target: self)
    end

    def barcode_type
      'SangerEan13'
    end

    def set_default_prefix
      self.barcode_prefix ||= BarcodePrefix.find_by(prefix: prefix)
    end
    private :set_default_prefix

    def sanger_human_barcode
      return nil if barcode.nil?
      prefix + barcode.to_s + Barcode.calculate_checksum(prefix, barcode)
    end

    def ean13_barcode
      return nil unless barcode.present? and prefix.present?
      Barcode.calculate_barcode(prefix, barcode.to_i).to_s
    end
    alias_method :machine_barcode, :ean13_barcode

    def role
      return nil if no_role?
      stock_plate.wells.first.requests.first.role
    end

    def no_role?
      case
      when stock_plate.nil?
        true
      when stock_plate.wells.first.nil?
        true
      when stock_plate.wells.first.requests.first.nil?
        true
      else
        false
      end
    end

    def external_identifier
      sanger_human_barcode
    end

    def printable_target
      self
    end

    def barcode!
      barcode
    end
  end

  InvalidBarcode = Class.new(StandardError)

  # Sanger barcoding scheme

  def self.prefix_to_number(prefix)
    first  = prefix.getbyte(0) - 64
    second = prefix.getbyte(1) - 64
    first  = 0 if first < 0
    second = 0 if second < 0
    ((first * 27) + second) * 1000000000
  end

  # NT23432S => 398002343283

  private

  def self.calculate_sanger_barcode(prefix, number)
      number_s = number.to_s
      raise ArgumentError, "Number : #{number} to big to generate a barcode." if number_s.size > 7
      human = prefix + number_s + calculate_checksum(prefix, number)
      barcode = prefix_to_number(prefix) + (number * 100)
      barcode = barcode + human.getbyte(human.length - 1)
  end

  def self.calculate_barcode(prefix, number)
    barcode = calculate_sanger_barcode(prefix, number)
    barcode * 10 + calculate_EAN13(barcode)
  end

  def self.calculate_checksum(prefix, number)
    string = prefix + number.to_s
    len = string.length
    sum = 0
    string.each_byte do |byte|
      sum += byte * len
      len = len - 1
    end
    (sum % 23 + 'A'.getbyte(0)).chr
  end

  def self.split_barcode(code)
    code = code.to_s
    if code.size > 11 && code.size < 14
      # Pad with zeros
      while code.size < 13
        code = '0' + code
      end
    end
    if /^(...)(.*)(..)(.)$/ =~ code
      prefix, number, check, printer_check = $1, $2, $3, $4
    end
    [prefix, number.to_i, check.to_i]
  end

  def self.split_human_barcode(code)
    if /^(..)(.*)(.)$/ =~code
      [$1, $2, $3]
    end
  end

  def self.number_to_human(code)
    barcode = barcode_to_human(code)
    prefix, number, check = split_human_barcode(barcode)
    number
  end

  def self.prefix_from_barcode(code)
    barcode = barcode_to_human(code)
    prefix, number, check = split_human_barcode(barcode)
    prefix
  end

  def self.prefix_to_human(prefix)
    human_prefix = ((prefix.to_i / 27) + 64).chr + ((prefix.to_i % 27) + 64).chr
  end

  def self.human_to_machine_barcode(human_barcode)
    human_prefix, bcode, human_suffix = split_human_barcode(human_barcode)
    # Bugfix Exception 8:39 am Dec 22th 2015
    #  undefined method `+' for nil:NilClass app/models/barcode.rb:101:in `calculate_checksum'
    # Incorrect barcode format
    if human_prefix.nil? || Barcode.calculate_checksum(human_prefix, bcode) != human_suffix
      raise InvalidBarcode, 'The human readable barcode was invalid, perhaps it was mistyped?'
    else
      calculate_barcode(human_prefix, bcode.to_i)
    end
  end

  def self.barcode_to_human(code)
    bcode = nil
    prefix, number, check = split_barcode(code)
    human_prefix = prefix_to_human(prefix)
    if calculate_barcode(human_prefix, number.to_i) == code.to_i
      bcode = "#{human_prefix}#{number}#{check.chr}"
    end
    bcode
  end

  # Returns the Human barcode or raises an InvalidBarcode exception if there is a problem.  The barcode is
  # considered invalid if it does not translate to a Human barcode or, when the optional +prefix+ is specified,
  # its human equivalent does not match.
  def self.barcode_to_human!(code, prefix = nil)
    human_barcode = barcode_to_human(code) or raise InvalidBarcode, "Barcode #{code} appears to be invalid"
    unless prefix.nil? or split_human_barcode(human_barcode).first == prefix
      raise InvalidBarcode, "Barcode #{code} (#{human_barcode}) does not match prefix #{prefix}"
    end
    human_barcode
  end

  def self.barcode_lookup(code)
    prefix, number, check = split_barcode(code)
    prefix = prefix_to_human(prefix)
    human_code = barcode_to_human(code)
    return nil unless human_code

    case prefix
      when 'ID'
        user = User.find_by barcode: human_code
        return user.login if user
      when 'LE'
        implement = Implement.find_by barcode: human_code
        return implement.name if implement
    end

    human_code
  end

  def self.check_EAN(code)
    # the EAN checksum is calculated so that the EAN of the code with checksum added is 0
    # except the new column (the checksum) start with a different weight (so the previous column keep the same weight)
    calculate_EAN(code, 1) == 0
  end

  def self.calculate_EAN13(code)
    calculate_EAN(code)
  end

  private

  def self.calculate_EAN(code, initial_weight = 3)
    # The EAN is calculated by adding each digit modulo 10 ten weighted by 1 or 3 ( in seq)
    code = code.to_i
    ean = 0
    weight = initial_weight
    while code > 0
      code, c = code.divmod 10
      ean += c * weight % 10
      weight = weight == 1 ? 3 : 1
    end

    (10 - ean) % 10
  end
end
