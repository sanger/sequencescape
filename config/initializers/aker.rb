# This config setting defines the mapping between models and attributes in Sequencescape and 
# attributes from the biomaterials service in Aker, as defined by the Job creation.

# To add a new mapping field from Aker:
#
# 1. Add the field name from aker as a value inside the corresponding list for the key with the SS table name 
#     in MAP_SS_TABLES_WITH_AKER
# 2. Add the field name from aker as a key linked with a column name for SS in MAP_AKER_WITH_SS_COLUMNS
#
# After this, if we want to update a new property from Aker into SS models we have to add the field name 
# from aker inside the list UPDATABLE_ATTRS_FROM_AKER_INTO_SS.
# 
# If we want to update a change in SS into the properties of Aker in the biomaterial service we have to add 
# the field name from aker inside the list UPDATABLE_ATTRS_FROM_SS_INTO_AKER.
# 
# SS updates will occur on update_attributes() calls
# Aker updates will happen on job completion, because the job message for the material is generated from
# the attributes() method of this class.
Aker::Material.set_config(
  {
    # Maps SS models with Aker attributes
    map_ss_tables_with_aker: {
      samples: [],
      sample_metadata: [:gender, :donor_id, :phenotype, :common_name],
      well_attribute: [:volume, :concentration]
    },

    # Maps SS column names with Aker attributes (if the name is different)
    map_aker_with_ss_columns: {
      volume: :measured_volume,
      common_name: :sample_common_name
    },

    # Aker attributes allowed to update from Aker into SS
    updatable_attrs_from_aker_into_ss: [
      :gender, :donor_id, :phenotype, :common_name,
      :volume, :concentration
    ],

    # Aker attributes allowed to update from SS into Aker
    updatable_attrs_from_ss_into_aker: [:volume, :concentration]
  }
)