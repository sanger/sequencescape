# frozen_string_literal: true

module FetchTable
  def fetch_table(selector)
    find(selector).all('tr').map do |row|
      row.all('th,td').map do |cell|
        cell.text.squish
      end
    end
  end
end
