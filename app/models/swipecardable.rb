# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2014,2015 Genome Research Ltd.

module Swipecardable
  def swipecard_code=(code)
    self.encrypted_swipecard_code = User.encrypt_swipecard_code(code)
  end

  def swipecard_code
  end

  def swipecard_code?
    encrypted_swipecard_code?
  end

  def compare_swipecard_code(code)
    User.encrypt_swipecard_code(code) == encrypted_swipecard_code
  end

  def self.included(base)
    base.class_eval do
      def self.encrypt_swipecard_code(code)
        User.encrypt(code, nil)
      end
     # won't work, because of the salt.
     scope :with_swipecard_code, ->(*swipecard_codes) { where(encrypted_swipecard_code: swipecard_codes.flatten.map { |sw| encrypt_swipecard_code(sw) }) }
    end
  end
end
