# Adelson's Checkerboard Shadow Illusion

A GLSL recreation of Adelson's checker shadow illusion. A light tile in shadow and a dark tile in direct light appear different, but have the same display code value.

Paste `checkerboard.glsl` into a new shader on [Shadertoy](https://www.shadertoy.com) to run it.

## Description

This shader raymarches a cylinder casting a soft shadow on a checkerboard. Parameters are tuned so a selected dark square in direct light and a selected light square in shadow render to similar linear intensities, recreating Adelson’s checker-shadow lightness illusion.

## Reference

* **Adelson, E. H. (2000).** Lightness Perception and Lightness Illusions. In M. Gazzaniga (Ed.), *The New Cognitive Neurosciences* (2nd ed., pp. 339–351). Cambridge, MA: MIT Press.
* **Adelson, E. H. (1995).** Checkershadow Illusion. [Perceptual Science Group, MIT](https://persci.mit.edu/gallery/checkershadow).
