# frozen_string_literal: true
module SamplesHelper # rubocop:todo Style/Documentation
  # Use this wherever you are editing a sample so that you get the sample 'common name' lookup
  # behaviour.  Attach 'data-organism' attribute to the 'common name' and 'taxon ID' fields
  # to get them updated.
  def organism_validation_javascript
    vite_javascript_tag('organism_validation')
  end
end
