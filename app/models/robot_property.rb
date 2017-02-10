# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

class RobotProperty < ActiveRecord::Base
  belongs_to :robot

  scope :beds, ->() {
    where(name: nil)
  }

  def ean13_barcode
    if name.nil?
      str = Barcode.calculate_barcode('BD', value.to_i).to_s
      if str.length == 12
        '0' + str
      else
        str
      end
    end
  end

  def sanger_human_barcode
    return nil unless name.nil?
    'BD' + value.to_s + Barcode.calculate_checksum('BD', value.to_i)
  end

  def barcode
    return nil unless name.nil?
    value.to_i
  end

  def sti_type
    self.class
  end
end
