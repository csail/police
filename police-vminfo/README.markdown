# police-vminfo

Collects information about the internals of the running Ruby VM.

This is useful for applications that want to re-implement standard library
objects such as String, or track their usage, e.g. for data flow taint tracking.
The code here can be used to ensure that an implementation fully covers an
object's methods.

Right now, this gem collects the Ruby exploration code used to build
police-dataflow.


## Copyright

Copyright (c) 2012 Massachusetts Institute of Technology. See LICENSE.txt for
further details.
