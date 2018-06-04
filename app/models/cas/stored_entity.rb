class Cas::StoredEntity < ApplicationRecord
  self.table_name = 'STORED_ENTITY'
  self.abstract_class = true

  establish_connection configurations["#{Rails.env}_cas"]

  def self.storage_location(barcode, barcode_prefix = 'DN')
    connection.select_all(%(
      select
      sa.name as STORAGE_AREA,
      sd.name as STORAGE_DEVICE,
      ba.name as BUILDING_AREA,
      b.description as BUILDING
      from
      stored_entity se,
      entity_movement em,
      storage_area_location sal,
      storage_area sa,
      device_location dl,
      storage_device sd,
      building_area ba,
      building b
      where se.prefix = '#{barcode_prefix}'
      and se.id_storedobject = #{barcode.to_i}
      and se.id_storage = em.id_storage
      and em.is_current = 1
      and em.id_sarealocation = sal.id_sarealocation
      and sal.is_current = 1
      and sal.id_area = sa.id_area
      and sal.id_device_location = dl.id_device_location
      and dl.is_current = 1
      and dl.id_storage_device = sd.id_storage_device
      and dl.id_buildingarea = ba.id_buildingarea
      and ba.id_building = b.id_building
    ))
  end
end
