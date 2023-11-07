---
layout: post
title: "Keyboard Plan"
subtitle: "" 
optimized_image: /files/CYBER60/thumb.png
category: Project Planning
tags:
  - Plan
---


# About

TODO

# PCB

This project uses the <a href="https://github.com/4pplet/cyber60">Cyber60</a> board by 4pplet. The board features 

- Holyiot YJ-18010 MCU
- nRF52840 Bluetooth module
- Open source ZMK firmware
- 2.75U+1U+2.75U split spacebar support
- <a href="https://cannonkeys.com/products/unified-s1-daughterboard-and-molex-cable?pr_prod_strat=use_description&pr_rec_id=28807589f&pr_rec_pid=7087153021039&pr_ref_pid=7117023379567&pr_seq=uniform">Unified USB C Daughterboard</a> support
- Hotswap switches via Mill-max sockets

<img src="/files/CYBER60/cyber60-MX_Rev_D1_Tray.png">

## Layout

The following keyboard layout is generated from <a href = "http://www.keyboard-layout-editor.com">Keyboard Layout Editor</a> and is useful for many tools which help automate keyboard design such as <a href = "http://builder.swillkb.com/">Plate & Case Builder</a>.

<img src="/files/CYBER60/keyboard-layout.png">

```
["~\n`","!\n1","@\n2","#\n3","$\n4","%\n5","^\n6","&\n7","*\n8","(\n9",")\n0","_\n-","+\n=",{w:2},"Backspace"],
[{w:1.5},"Tab","Q","W","E","R","T","Y","U","I","O","P","{\n[","}\n]",{w:1.5},"|\n\\"],
[{w:1.75},"Caps Lock","A","S","D","F","G","H","J","K","L",":\n;","\"\n'",{w:2.25},"Enter"],
[{w:2.25},"Shift","Z","X","C","V","B","N","M","<\n,",">\n.","?\n/",{w:2.75},"Shift"],
[{w:1.5},"Ctrl",{w:1.25},"Win",{w:1.5},"Alt",{a:7,w:2.75},"",{w:1},"",{a:7,w:2.75},"",{a:4,w:1.5},"AltGr",{w:1.25},"Win",{w:1.5},"Ctrl"]
```

# ZMK Firmware

TODO

## Pointing Device Support

Pointing devices are not currently not supported in the release version of ZMK, however, the feature branch from <a href="https://github.com/urob">urob</a> has an implementation pending PR.

While it is generally possible to integrate a pointing device with the MCU, there are not enough free _accessible_ pins to do so. Three GPIO pins are needed. Since I will not be using a rotary encoder, `ROT_A` and `ROT_B` provide two pins. The third will need to be repurposed from another component. 4pplet recommends using the buzzer or caplock LED, however, modifications are necessary.

<img src="/files/CYBER60/4pplet_email.png">

Instead, I will implement pointing mouse emulation via IJKL keys.

### Implementation

- Update `west.yml` to point to feature branch <a href = "https://www.reddit.com/r/ErgoMechKeyboards/comments/w39hpt/zmk_users_how_to_add_mouse_keys/igv6cex/
https://github.com/urob/zmk-config/tree/main/config">(Reference)</a>
- Mouse emulation is not currently supported in GUI keyboard editing tools, so has to be manually added to keymap file
- <a href = "https://deploy-preview-778--zmk.netlify.app/docs/behaviors/mouse-emulation/">Draft ZMK documenation</a>
- https://rfong.github.io/rflog/2021/10/26/r61-trackpoint-pt2/
- https://github.com/manna-harbour/crkbd/tree/master/trackpoint#driver-board

# Inspiration

Thick frame, hard edges, angular, and heavy. Inspiration:

Keychron - thick case, sculpted base
<img src="/files/CYBER60/keychronq1.png">
<img src="/files/CYBER60/keychronq4.png">

ZT60 - clean
<img src="/files/CYBER60/ZT60.png">

Poseidon Defender - thick
<img src="/files/CYBER60/Defender.png">

Brutal V2 - angles
<img src="/files/CYBER60/BrutalV2.png">

Stacked leather and satin finish for the body
<img src="/files/CYBER60/Stackedleather.png">

PBTfans Retro Dark Light keycaps
<img src="/files/CYBER60/large_10314_large_KBDPT17-3_1.jpg>




# Case

I think that to minimize raw material cost and constrain machining complexity, a sandwitch construction using metal sheet may be viable. The 

| Layer                | Thickness           | Material |
|----------------------|---------------------|----------|
| Top plate            | 5mm                 | Metal    |
| Body                 | 7mm                 | Leather  |
| Transparent diffuser | 1/8"                | Acrylic  |
| Base (wedge)         | 11mm (at thickest)  | Metal    |

## Materials

For the metal and acrylic, each plate requires minimally 13"x5" of material.

- Easy-to-Machine Multipurpose 304 Stainless Steel Sheet
  - 12"x18"x1/4" ($143.13)
    - https://www.mcmaster.com/6620K186
    - For top/bottom plates
  - 6"x12"x1/2" ($143.13)
    - https://www.mcmaster.com/6620K117
    - For wedge

- Multipurpose 6061 Aluminum Sheet
  - 6"x48"x1/4" ($60.18)
    - https://www.mcmaster.com/9246K424
    - For top/bottom plates
  - 6"x12"x5/8" ($45.78)
    - https://www.mcmaster.com/9246K524
    - For wedge

- Clear Scratch- and UV-Resistant Cast Acrylic ($17.70)
  - 12"x24"x1/8"
    - https://www.mcmaster.com/8560K257
    - For diffuser

- M3x0.5mm screws (3mm) 
  - Tap Drill: 2.5/#39
  - Clearance Drill: 3.30/#30  
  - For attaching base https://www.mcmaster.com/products/screws/thread-size~m3/metric-18-8-stainless-steel-hex-drive-flat-head-screws/

## Design

Profile

<img src="/files/CYBER60/draw2.png">

<img src="/files/CYBER60/draw8.png">

<img src="/files/CYBER60/draw9.png">

All of the layers unstacked

<img src="/files/CYBER60/draw1.png">

Top plate (with slight fillet) and leather stack

<img src ="/files/CYBER60/draw11.png">

PCB is tray mounted to the standoffs and the sides sit on the acrylic lip

<img src="/files/CYBER60/draw3.png">

<img src="/files/CYBER60/draw10.png">

The base plate has a cutout for a battery and the inner area is index to facilitate construction of the leather body via a manufactured spacing jig

<img src="/files/CYBER60/draw5.png">

The base wedge is the most complicated part and requires machining from two faces.

- From the top, a recess is needed to facilitate the USB C daughterboard and connector
- From the bottom, establishing the wedge shape and cutouts for the soft feet 

<img src="/files/CYBER60/draw6.png">

<img src="/files/CYBER60/draw7.png">

## Construction Considerations

### Machining

???

### Leather stack

## Things To Figureout

### Pressing the leather stack

General idea: https://www.instructables.com/Stacked-Leather-Knife-Handle/

- No visible holes drilled through the top plate
  - Thread 3mm
- 17mm of thread when compressed
  - Ignore the acrylic layer during forming of leather
- Bottom plate needs to be fully drilled through
  - M3x0.5mm x 30mm long
  - Progressively press using hex nuts and teflon washers
- Bottom plate is _indexed_ for acrylic cutout(s) to be stacked in order for keeping the leather true

### O-ring assembly

- 3mm standoffs or 1/8" ???
  - https://www.mcmaster.com/products/nuts/standoffs~/thread-locking-male-female-threaded-hex-standoffs/

### USB Port

- USB C to JST connector
  - https://cannonkeys.com/products/unified-c4-daughterboard
  - Yes this is compatible

  - https://cannonkeys.com/products/unified-s1-daughterboard-and-molex-cable?pr_prod_strat=use_description&pr_rec_id=28807589f&pr_rec_pid=7087153021039&pr_ref_pid=7117023379567&pr_seq=uniform
  - https://cannonkeys.com/products/molex-and-jst-cables?variant=41098401972335
- USB port access like this: https://cannonkeys.com/products/zoom-tkl-ae