# frozen_string_literal: true

# This file contains helper methods for working with the Integration Hub (Sapio) in RSpec tests.
module SapioHelper
  def create_sapio_study(**attributes)
    previous_api_application = Current.api_application
    Current.api_application ||= create(:api_application, name: 'Integration Hub')

    create(:study, mastered_in_sapio: true, **attributes)
  ensure
    Current.api_application = previous_api_application
  end
end
