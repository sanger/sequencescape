# frozen_string_literal: true

# This file contains helper methods for working with tables in RSpec tests.

module TableHelper
  def fetch_table(selector)
    find(selector).all('tr').map { |row| row.all('th,td').map { |cell| cell.text.squish } }
  end
end
