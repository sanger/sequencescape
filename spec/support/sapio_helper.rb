# frozen_string_literal: true

# This file contains helper methods for working with the Integration Hub (Sapio) in RSpec tests.
module SapioHelper
  def create_sapio_study(**attributes)
    Current.api_application = create(:api_application, name: 'Integration Hub')

    create(:study, mastered_in_sapio: true, **attributes)
  ensure
    Current.reset
  end
end
