When 'I retrieve the XML for the receptacle in {asset_name}' do |tube|
  page.driver.get(receptacle_path(id: tube.receptacle, format: :xml), 'Accepts' => 'application/xml')
end
