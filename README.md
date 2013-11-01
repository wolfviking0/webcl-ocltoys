webcl-ocltoys
=============

WebCL version of [OCLToys](http://code.google.com/p/ocltoys/) with [webcl-translator](https://github.com/wolfviking0/webcl-translator)


You need to download [Boost](http://www.boost.org/users/download/) and [WebCL-translator](https://github.com/wolfviking0/webcl-translator) first.

Change the path of the boost and translator folder inside the Makefile.

You can launch the samples with parameter just use :

_ocltoys.html?gl=on&-w&[256, 512, 1024]&-h&[256, 512, 1024]&-o&[ALL, ALL_GPUS, ALL_CPUS, FIRST_GPU, FIRST_CPU]

See all the webcl demo [here](http://wolfviking0.github.io/webcl-translator/)