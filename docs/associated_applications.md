# @title Associated Applications
# Associated Applications

This file contains a brief summary of some of Sequencescape's clients and
dependencies.

# Clients

## Limber
Controls the majority of the library creation pipelines. A Sequencescape client
with no persistence layer of its own. Instead it interacts with Sequencescape via
both API V1 and API V2.

[Github](https://github.com/sanger/limber)

## Traction
Library and Sequencing pipeline for Long-Read teams. Mostly handles its own
persistence, but uses Sequencescape API to import some intial information.

[Github (UI)](https://github.com/sanger/traction-ui)
[Github (Backend)](https://github.com/sanger/traction-service)
[Github (V1)](https://github.com/sanger/traction) (Deprecated)

## Gatekeeper
Allows registration and QC of Tag plates and Reporter plates. A Sequencescape client
with no persistence layer of its own. Instead it interacts with Sequencescape, mostly
via API V1.

[Github](https://github.com/sanger/gatekeeper)

## Asset Audits / Process Tracker
Simple tracking application to record the performance of tasks. Has its own
persistence and also creates {AssetAudit asset audits} in Sequencescape to track
the actions it has recorded.

[Github](https://github.com/sanger/asset_audits)

# Dependencies

## Print my Barcode
Barcode printing service, that handles populating pre-registered templates
and sending them to the barcode printers.

[Github](https://github.com/sanger/print_my_barcode)

## Plate Barcode
Connects to a concurrency safe counter in an Oracle database to generate barcode
numbers. The counter is shared by other teams within Sanger. Removal of this
dependency will require us switching the plate barcode format away from the current
DN numbers, as otherwise there is the risk of clashing barcodes.

@see PlateBarcode

[Github](https://github.com/sanger/plate_barcode)

# Deprecated Applications

These applications are either no longer running, or are due to be shut off and
are not expected to have any active users. However there may still be supporting
code within Sequencescape. Generally speaking, while behaviour associated with
these apps can be stripped out, the *data* should remain intact.

## Aker
Intended as a customer facing replacement to the Manifests and Submission components
of Sequencescape. Allowing a shared front-end for multiple LIMS. Actually comprised
a suite of applications.

[Github](https://github.com/sanger?utf8=✓&q=aker&type=&language=)

## Generic Lims
Library pipeline application for Bespoke (then Illumina-C). Now part of Limber,
operated in a very similar manner. Contained PCR, PCR Free and Chromium (10x)
pipelines.

[Github](https://github.com/sanger/illumina_c_pipeline)

## Illumina-B Lims
Library pipeline application for High-Throughput (then Illumina-B). Contained WGS,
and ISC pipelines. Now part of Limber (was actually forked to create Limber).

[Github](https://github.com/sanger/illumina_b_pipeline)

## Pulldown app
Library pipeline application for Illumina-A, contained various sequence capture
pipelines. Forked to create Illumina-B app, then later merged in when Illumina-A
and B merged.

[Github](https://github.com/sanger/pulldown_pipeline)
