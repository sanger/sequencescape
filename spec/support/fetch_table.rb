# frozen_string_literal: true

module FetchTable
  def fetch_table(selector)
    find(selector).all('tr').map { |row| row.all('th,td').map { |cell| cell.text.squish } }
  end
end
