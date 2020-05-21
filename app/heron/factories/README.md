# Heron Factories

## ::Heron::Factories::Plate / ::Heron::Factories::TubeRack

### Recipients

Plates and racks could contain recipients which are each of the positions in them (A1, B1, etc...).
A recipient for a plate would represent a well, while for a rack it would represent a tube. 
At now only racks allow to write data in their recipients by specifying a barcode for the tube.

A plate cannot be created empty. When we create an empty plate the plate purpose will trigger
the creation of all its wells:

```ruby
# This creates a plate with barcode 1 and all its associated wells from purpose with uuid uuid
::Heron::Factories::Plate.new({barcode: "1", purpose_uuid: "uuid"}).save
```

A rack can be created empty, without any tubes:

```ruby
# This creates an empty tube rack with barcode 1 and purpose uuid
::Heron::Factories::TubeRack.new({barcode: "1", purpose_uuid: "uuid"}).save
```

Or we can specify the tubes with their barcodes:

```ruby
# This creates two tubes with barcodes 2 and 3 under rack with barcode 1
::Heron::Factories::TubeRack.new({
  barcode: "1", purpose_uuid: "uuid",
  tubes: {
    "A1": { barcode: '2'},
    "A2": { barcode: '3', contents: {name: 'A sample'}}
  }}).save
```

By default tubes will be created as Standard sample tubes. However, if specified, a tube can be created
of a different tube purpose:

```ruby
# This creates a tube at A1 of purpose with uuid uuid2
::Heron::Factories::TubeRack.new({
  barcode: "1", purpose_uuid: "uuid",
  tubes: {
    "A1": { barcode: '2', purpose_uuid: "uuid2"}
  }}).save
```
### Contents

Contents represents the samples inside a position in a plate or rack. Contents attributes represent
sample information and they can be expressed under the 'contents' key inside a recipient as a list
or as an object.

A sample needs to be created under a study, so specifying the contents for well or tube means that 
study uuid will be mandatory.

```ruby
# This creates a tube rack with barcode 1 and purpose uuid and a tube with barcode 2 that contains a
# sample with name 'A sample', under study uuid2
::Heron::Factories::TubeRack.new({
  barcode: "1", purpose_uuid: "uuid", study_uuid: "uuid2", 
  tubes: {"A1": {barcode: "2", contents: {name: "A sample"}}}}).save
```

Study uuid can be defined at rack/plate level or at sample level. Rack/Plate level takes precedence on sample.

```ruby
# This creates a tube rack with barcode 1 and purpose uuid and a tube with barcode 2 that contains a
# sample with name 'A sample', under study uuid2
::Heron::Factories::TubeRack.new({
  barcode: "1", purpose_uuid: "uuid", 
  tubes: {"A1": {barcode: "2", contents: {name: "A sample", study_uuid: "uuid2"}}}}).save
```

Contents attributes can update any column from Sample and Sample::Metadata tables:

```ruby
# This creates a tube rack with barcode 1 and purpose uuid and a tube with barcode 2 that contains a
# sample with supplier_name 'My supplier' that act as a Negative control.
::Heron::Factories::TubeRack.new({
  barcode: "1", purpose_uuid: "uuid", study_uuid: "uuid2", 
  tubes: {"A1": {barcode: "2", contents: {
    supplier_name: "My supplier", control: true, control_type: 'Negative'}}}}).save
```

A tube or well might contain samples already existing so they are retrieved and created as aliquots in the 
tube or well. To refer to an already created sample we can use the uuid of the sample in 'sample_uuid':

```ruby
# This creates a tube rack with barcode 1 and purpose uuid and a tube with barcode 2 that contains an
# already existing sample that had uuid uuid3
::Heron::Factories::TubeRack.new({
  barcode: "1", purpose_uuid: "uuid", study_uuid: "uuid2", 
  tubes: {"A1": {barcode: "2", contents: {sample_uuid: "uuid3"}}}}).save
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