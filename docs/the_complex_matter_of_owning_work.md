<!--
# @title The complex matter of owning work
-->
# The complex matter of owning work

There are two main categories of ownership we'll be taking about here:

1. {Project} - Who is paying for it.
2. {Study} - Who is interested in it. This has the dual role of grouping work and stuff together for organisation,
             and grouping it together for means of data-release.

We'll also be considering the various things that can be 'owned' in particular:

1. Stuff - Such as {Labware} and {Receptacle receptacles} or, slightly more abstract {Sample samples}
2. Work - Processes actually performed of stuff to yield more stuff, or data. Mostly represented by {Submission}, {Order}
          and {Request}.

In the early days, things were a little more simple. A {Receptacle} only contained a single {Sample} and so was only generally
of interest to one owner at a time. Occasionally a sample may be sequenced under more than one {Study} but this wasn't too much
of a problem, as the {Lane} and {SequencingRequest} could be assigned to a different {Study} each time.

Then came multiplexing, and a {Receptacle} could contain lots of different stuff in the form of {Aliquots}. At first
we ensured they all belonged to a single {Study} and {Project}, but soon this restricted throughput too much, and so
cross-{Study} and cross-{Project} pools were born. This made things complicated.

First, the simple bits:

{Aliquot} - Is still pretty simple. We assign each to a single {Study} and {Project} and this largely works. It does mean
            that stock aliquots have a de-facto study, but this is generally not a major limitation. There are some difficulties
            with accessioning and the premature linking of a sample to a study, but that is more an issue of {Study} having
            too many roles.
{Sample} - Samples can belong to multiple {Study studies}. This is probably best seen as an organizational tool.

Then the difficulties.

{Request} - Is the smallest representation of requested work. It is usually associated with both a {Study} and a {Project}.
            However, this model fails to correctly handle the processing of cross-project/study pools, as a single request
            may represent work for more than one study/project. Pre-multiplexing each {Request} can be associated
            with a single {Order}, however post multiplexing, a {Request} may be shared by all orders in a submission.
{Order} - The manner in which requests are constructed. Collects together a group of {Receptacle receptacles} and builds
          {Request requests} for them. Has a {Study} and {Project} and uses this on the requests it builds. Both {Study}
          and {Project} are required for most orders. However, if the source assets are cross-study/project this requirement
          is removed, and the corresponding attribute is nil.
{Submission} - Group together orders.

This makes it very difficult to easily and reliably establish ownership of all requests. We need to consider the following
situations:

1) Stuff under study A has work requested under study B. In this case the source {Receptacle} remains owned by study A,
   the request is owned by study B, and the target receptacle (ie. the new stuff) is owned by study B.
2) A multiplexed library tube contains Aliquots owned by {Study} and study B. It gets sequenced. The Request ends up
   belonging to no one, and the Lane contains Aliquots belonging to study A and study B.

And then some situations which just don't work:

1) A multiplexed library tube contains Aliquots owned by {Study study A} and study B. Its about to get re-sequenced, but this time
   under studies C and D. We could store the new studies on the aliquots in the target lanes, but currently have no means
   of actually achieving this as this information is usually populated by the {Request}.
