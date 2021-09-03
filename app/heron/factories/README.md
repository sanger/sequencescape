# Heron Factories

## ::Heron::Factories::Sample

A sample factory can create a new Sample and its associated Sample::Metadata instances.
A study is mandatory for the creation of the sample.
By default, any sample will be created with a generated name and sanger_sample_id making use
of the Study abbreviation:

```ruby
# This creates a sample belonging to study with uuid uuid and will use the study abbreviation
# to generate the name and the sanger_sample_id
::Heron::Factories::Sample.new({ study_uuid: 'uuid' }).create
```

However, we can overwrite these values, or any other field in the Sample and Sample::Metadata
tables by using their column name:

```ruby
# This creates a sample belonging to study with uuid uuid and will use the study abbreviation
# to generate the sanger_sample_id. The name will by 'Mysample'
::Heron::Factories::Sample.new({ study_uuid: 'uuid', name: 'My sample' }).create
```

By default, the same value from sanger_sample_id will be applied in the name and sanger_sample_id
columns.

```ruby
# This creates a sample belonging to study with uuid uuid and will have name and sanger_sample_id as
# 'Mysample'
::Heron::Factories::Sample.new({ study_uuid: 'uuid', sanger_sample_id: 'Mysample' }).create
```

If a sample_uuid is provided it won't create a new sample, but retrieve an already existing
one that uses that uuid. In this case we don't need to specify the study.
**Beware!** if the uuid you supply does not exist, and you specify a study, it will create a new sample
and ignore the uuid you've specified.

```ruby
# This will return an already existing sample with uuid 'existing_uuid'
::Heron::Factories::Sample.new({ sample_uuid: 'existing_uuid' }).create
```

We can create a new sample and enforce to use a uuid supplied as attribute by specifying
the attribute `uuid`:

```ruby
# This will create a new sample and assign to it the uuid 'uuid1':
::Heron::Factories::Sample.new({ study_uuid: 'uuid', uuid: 'uuid1' }).create
```

Once we have a factory we can use it to create aliquots in a recipient as well (inside a tube, or a well):

```ruby
# This will create an aliquot of sample with uuid existing_uuid in position A01 of plate with barcode 1234
well = Plate.with_barcode('1234').wells.located_at('A01')
::Heron::Factories::Sample.new({ sample_uuid: 'existing_uuid' }).create_aliquot_at(well)
```

Aliquots properties can be added so the aliquots created for this sample will be applied on creation:

```ruby
# This will create an aliquot of sample with uuid existing_uuid in position A01 of plate with barcode 1234
# with tag id 1
well = Plate.with_barcode('1234').wells.located_at('A01')
::Heron::Factories::Sample.new({ sample_uuid: 'existing_uuid', aliquot: { tag_id: 1 } }).create_aliquot_at(well)
```

## ::Heron::Factories::Plate / ::Heron::Factories::TubeRack

Plate and TubeRack factories share the same specicification for their recipients and contents.

### About Recipients (wells and tubes)

Plates and racks could contain recipients which are each of the positions in them (A1, B1, etc...).
A recipient for a plate would represent a well, while for a rack it would represent a tube.
At now only racks allow to write data in their recipients by specifying a barcode for the tube.

A plate cannot be created empty. When we create an empty plate the plate purpose will trigger
the creation of all its wells:

```ruby
# This creates a plate with barcode 1 and all its associated wells from purpose with uuid uuid
::Heron::Factories::Plate.new({ barcode: '1', purpose_uuid: 'uuid' }).save
```

A rack can be created empty, without any tubes:

```ruby
# This creates an empty tube rack with barcode 1 and purpose uuid
::Heron::Factories::TubeRack.new({ barcode: '1', purpose_uuid: 'uuid' }).save
```

Or we can specify the tubes with their barcodes:

```ruby
# This creates two tubes with barcodes 2 and 3 under rack with barcode 1
::Heron::Factories::TubeRack.new(
  {
    barcode: '1',
    purpose_uuid: 'uuid',
    tubes: {
      'A1': {
        barcode: '2',
      },
      'A2': {
        barcode: '3',
        contents: {
          name: 'A sample',
        },
      },
    },
  },
).save
```

By default tubes will be created as Standard sample tubes. However, if specified, a tube can be created
of a different tube purpose:

```ruby
# This creates a tube at A1 of purpose with uuid uuid2
::Heron::Factories::TubeRack.new(
  { barcode: '1', purpose_uuid: 'uuid', tubes: { 'A1': { barcode: '2', purpose_uuid: 'uuid2' } } },
).save
```

### About Contents (aliquots of samples)

Contents represents the samples inside a position in a plate or rack. Contents attributes represent
sample information and they can be expressed under the 'contents' key inside a recipient as a list
or as an object.

A sample needs to be created under a study, so specifying the contents for well or tube means that
study uuid will be mandatory.

```ruby
# This creates a tube rack with barcode 1 and purpose uuid and a tube with barcode 2 that contains a
# sample with name 'A sample', under study uuid2
::Heron::Factories::TubeRack.new(
  {
    barcode: '1',
    purpose_uuid: 'uuid',
    study_uuid: 'uuid2',
    tubes: {
      'A1': {
        barcode: '2',
        contents: {
          name: 'A sample',
        },
      },
    },
  },
).save
```

Study uuid can be defined at rack/plate level or at sample level. Rack/Plate level takes precedence on sample.

```ruby
# This creates a tube rack with barcode 1 and purpose uuid and a tube with barcode 2 that contains a
# sample with name 'A sample', under study uuid2
::Heron::Factories::TubeRack.new(
  {
    barcode: '1',
    purpose_uuid: 'uuid',
    tubes: {
      'A1': {
        barcode: '2',
        contents: {
          name: 'A sample',
          study_uuid: 'uuid2',
        },
      },
    },
  },
).save
```

Contents attributes can update any column from Sample and Sample::Metadata tables:

```ruby
# This creates a tube rack with barcode 1 and purpose uuid and a tube with barcode 2 that contains a
# sample with supplier_name 'My supplier' that act as a Negative control.
::Heron::Factories::TubeRack.new(
  {
    barcode: '1',
    purpose_uuid: 'uuid',
    study_uuid: 'uuid2',
    tubes: {
      'A1': {
        barcode: '2',
        contents: {
          supplier_name: 'My supplier',
          control: true,
          control_type: 'Negative',
        },
      },
    },
  },
).save
```

A tube or well might contain samples already existing so they are retrieved and created as aliquots in the
tube or well. To refer to an already created sample we can use the uuid of the sample in 'sample_uuid':

```ruby
# This creates a tube rack with barcode 1 and purpose uuid and a tube with barcode 2 that contains an
# already existing sample that had uuid uuid3
::Heron::Factories::TubeRack.new(
  {
    barcode: '1',
    purpose_uuid: 'uuid',
    study_uuid: 'uuid2',
    tubes: {
      'A1': {
        barcode: '2',
        contents: {
          sample_uuid: 'uuid3',
        },
      },
    },
  },
).save
```

A recipient (tube or well) can also contain more than one sample. We can provide a list of contents for
it, where each element of the list will be an object representing one of the samples. Sequencescape
database requires different settings in the aliquots created for each sample when they are contained in
same recipient, the settings for the aliquots table can be specified under the 'aliquot' field:

```ruby
# Example: Two aliquots in tube at position B1 from samples with name 'Sample 1' and 'Sample 2'
#    first belong to study <uuid> and has tag with id § and second to study <uuid2> and tag id 2.
::Heron::Factories::TubeRack.new({
  barcode: "1", purpose_uuid: "uuid",
  tubes: {
     'B1': {
        barcode: '2',
        content: [{name: 'Sample 1', study_uuid: <uuid>, aliquot: {tag_id: 1}},
                  {name: 'Sample 2', study_uuid: <uuid2>, aliquot: {tag_id: 2}}] } }
}).save
```
