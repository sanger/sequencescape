# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

module Sanger
  module Testing
    module Model
      module Macros
        def should_default_everything_but(properties_type, *keys)
          properties_type.defaults.reject { |k, _v| keys.include?(k) }.each do |name, value|
            should "leave the value of #{name} as default" do
              assert_equal(value, subject.send(name))
            end
          end
        end

        def should_default_everything(properties_type)
          should_default_everything_but(properties_type)
        end
      end
    end
  end
end
