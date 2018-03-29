# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2014,2015,2016 Genome Research Ltd.

class Barcode
  require 'sanger_barcode_format'
  require 'sanger_barcode_format/legacy_methods'
  extend SBCF::LegacyMethods

  # Anything that has a barcode is considered barcodeable.
  module Barcodeable
    def self.included(base)
      base.class_eval do
        before_create :set_default_prefix
        class_attribute :prefix
        self.prefix = 'NT'

        after_save :broadcast_barcode, if: :saved_change_to_barcode?
      end
    end

    def generate_barcode
      self.barcode = AssetBarcode.new_barcode
    end

    def broadcast_barcode
      Messenger.new(template: 'BarcodeIO', root: 'barcode', target: self).broadcast
    end

    def barcode_format
      'SangerEan13'
    end

    def set_default_prefix
      self.barcode_prefix ||= purpose.barcode_prefix
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

  # What?! Where is everything?

  # Don't worry, your usual methods are available, however it is probably
  # better to take a look over at:
  # https://github.com/sanger/sanger_barcode_format
  # Or the docs at:
  # http://www.rubydoc.info/github/sanger/sanger_barcode_format/development/

  # Extracted from the sanger_barcode_format Readme:
  # # Using builders
  # barcode = SBCF::SangerBarcode.from_human('DN12345R')
  # barcode = SBCF::SangerBarcode.from_machine(4500101234757)
  # barcode = SBCF::SangerBarcode.from_prefix_and_number('EG',123)

  # # Using standard initialize
  # barcode = SBCF::SangerBarcode.new(prefix:'EG',number:123)
  # barcode = SBCF::SangerBarcode.new(human_barcode:'DN12345R')
  # barcode = SBCF::SangerBarcode.new(hmachine_barcode:4500101234757)

  # # Converting between formats
  # barcode = SBCF::SangerBarcode.new(prefix:'PR',number:1234)
  # barcode.human_barcode # => PR1234K'
  # barcode.machine_barcode # => 4500001234757

  # # Pulling out components
  # barcode = SBCF::SangerBarcode.new(machine_barcode: 4500001234757)
  # barcode.prefix.human # => 'PR'
  # barcode.checksum.human # => 'K'
end
