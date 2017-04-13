# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2013,2015 Genome Research Ltd.

module Request::CustomerResponsibility
  def self.included(base)
    base::Metadata.class_eval do
      attribute(:customer_accepts_responsibility, boolean: true)
      validate :customer_can_accept_responsibility?, if: :customer_accepts_responsibility_changed?, on: :update

      def customer_can_accept_responsibility?
        return true unless request.try(:failed?)
        errors.add(:customer_accepts_responsibility, 'can not be changed once a request is failed.')
        raise ActiveRecord::RecordInvalid, self
      end
    end
  end
end
