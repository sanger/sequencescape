# frozen_string_literal: true

module VisitHelper
  # Navigates to a path and relies on Capybara's waiting behavior by asserting the page title.
  # The title should be the text that follows the "Sequencescape | " prefix in the <title> tag.
  def visit_and_wait_for_title(path, expected_title)
    visit(path)
    expect(page).to have_title("Sequencescape | #{expected_title}")
  end
end
