# frozen_string_literal: true

# Automatically generate the plate types listed in
# config/default_records/plate_types/*.yml
RecordLoader::PlateTypeLoader.new.create!
