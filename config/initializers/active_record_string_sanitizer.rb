# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

module ActiveRecord::StringSanitizer
  def self.extended(base)
    base.instance_eval do
      def squishify(*names)
        class_eval do
          before_save do |record|
            names.each do |name|
              value = record.send(name)
              record.send(name.to_s + '=', value.squish) if value.is_a? String
            end
          end
        end
      end
    end
  end
end

class ActiveRecord::Base
  extend ActiveRecord::StringSanitizer
end
