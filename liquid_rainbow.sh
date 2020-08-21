#!/bin/bash

# generates liquid gif with a rainbow gradient.
# usage: ./liquid_rainbow.sh
# After a while a liquid gif will be created with a rainbow gradient

# define size of the canvas (actual animation will be slightly smaller than this)
size=500

radius=$(($size/2))

# generate random seed for plasma image
random=$(($RANDOM))

#generate random colour for second plasma image
hex=$(for i in $(seq 1 6); do echo -n $(echo "obase=16; $(($RANDOM % 16))" | bc); done; echo)

# generate random number for saturation
saturation=$(echo $((50 + (RANDOM % 200))))

# generate random number for hue
hue=$(echo $((RANDOM % 200)))

# generate random number for blur
blur=$(echo $((5 + (RANDOM % 20))))

# generate random number for the frquency of the sinusoid function
frequency=$(echo $((1 + (RANDOM % 5))))

# generate the input image. It's imagemagick's blurred random hues masked by a circle (this gives us transparent areas and it's a nice shape) https://www.imagemagick.org/Usage/canvas/#random_blur
convert \
	\( -size "$size"x"$size" xc:none -fill white -draw "circle "$radius","$radius" "$radius",50" \) \
	null: \
	\( -size "$size"x"$size" \
		xc: +noise Random \
		-virtual-pixel tile \
		-blur 0x10 \
		-auto-level \
		-separate -background white \
          	-compose ModulusAdd \
          	-flatten \
          	-channel R \
          	-combine \
          	+channel \
          	-set colorspace HSB \
          	-colorspace RGB \
         \) \
	-modulate 100,$saturation,$hue \
	-compose SrcIn \
	-layers composite \
	gradient.png

# I mostly stole this bit from here https://www.imagemagick.org/Usage/canvas/#random_ripples

convert \
	-size "$size"x"$size" \
	xc: +noise Random \
	random.png

for i in `seq 0 10 359`; do
	j=`expr $i \* 5`
	convert random.png -channel G \
		-function Sinusoid 1,${i} \
		-virtual-pixel tile -blur 0x$blur -auto-level \
		-function Sinusoid $frequency,${j} \
		-separate +channel miff:-
	done |	convert miff:- -set delay 12 -loop 0 displacement_map.gif

# here it is composited all together. The 
convert \
	-dispose background \
	gradient.png null: \
	displacement_map.gif \
	-compose displace \
	-define compose:args=10x40 \
	-layers composite \
	liquid_rainbow.gif

# clean up temporary files
rm displacement_map.gif random.png gradient.png
