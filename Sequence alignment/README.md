# Multi-view object recognition

Measures multi-view object recognition peroformance based on sequence alignment. Object maps are constructed for each object containing multiple views. Multi and Single-view object recognition are compared in this algorithm.

![Sequence alignment flow diagram](https://raw.githubusercontent.com/ldelange/mv_objrecog/master/mvflow.png)

## Descriptors

The [vl_feat](http://www.vlfeat.org/) library for MATLAB is used for feature extraction

* Local binary patterns
* Histogram oriented gradients
* Hue, saturation, value
* Neural Networks (imagenet-vgg-verydeep-16.mat)

## Image dataset

[RGB-D dataset](http://rgbd-dataset.cs.washington.edu/)
```
Objects: 	51
Instances:	4 ~ 8
Views: 		30 ~ 50
Height:		30, 45, 60 degrees
```

## Getting started

Place all .m files inside a directory containing the following externally downloaded libraries and run main.m

* matconvnet
* vlfeat
* rgbd-dataset
