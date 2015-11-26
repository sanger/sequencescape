def fetch_table(selector)
  find(selector).all('tr').map {|row| row.all('th,td').map {|cell| cell.text.squish }}
end

begin
  require 'pry'
rescue
end
