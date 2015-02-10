#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011 Genome Research Ltd.
module Sanger
  module Testing
    module View
      module Macros
        # Quick and dirty way to check for a form.  Passed block should return the 'action' that will be
        # performed.  The other parameters are as to +assert_select+.  Checks for the presence of a submit
        # button within the form.
        def should_have_a_form_to(*form_select_options, &block)
          should 'have a form' do
            css_selector, replacements_in_selector = form_select_options

            form_selector = 'form[method=post][action=?]'
            form_selector << css_selector unless css_selector.nil?

            replacements_in_selector ||= []
            replacements_in_selector.unshift(instance_eval(&block))

            assert_select(form_selector, *replacements_in_selector) do
              assert_select('input[type=submit]')
            end
          end
        end
      end
    end
  end
end
