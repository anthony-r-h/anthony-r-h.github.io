---
layout: post
title: "Keyboard Plan"
subtitle: "" 
optimized_image: /files/CYBER60/thumb.png
category: Keyboard
tags:
  - Plan
  - KB60
math: true
---

This project uses readily available, open-source components as the starting point to bridge the the requisite skills to design and build a completely custom keyboard, starting from the the PCB design phase. The goal of this project is to build a premium, wireless, split spacebar keyboard powered by ZMK.

<h2>Table Of Contents</h2>
<p style="margin-bottom:29px;"></p>


* toc
{:toc}


# PCB and Firmware

## Cyber60 PCB

This project uses the <a href="https://github.com/4pplet/cyber60">Cyber60</a> board by 4pplet. The board features:

- Holyiot YJ-18010 MCU
- nRF52840 Bluetooth module
- Open source ZMK firmware
- 2.75U+1U+2.75U split spacebar support
- <a href="https://cannonkeys.com/products/unified-s1-daughterboard-and-molex-cable?pr_prod_strat=use_description&pr_rec_id=28807589f&pr_rec_pid=7087153021039&pr_ref_pid=7117023379567&pr_seq=uniform">Unified USB C Daughterboard</a> support
- Hotswap switches via Mill-max sockets

<img src="/files/CYBER60/cyber60-MX_Rev_D1_Tray.png">

### Layout

The following keyboard layout is generated from <a href = "http://www.keyboard-layout-editor.com">Keyboard Layout Editor</a> and is useful for many tools which help automate keyboard design such as <a href = "http://builder.swillkb.com/">Plate & Case Builder</a>.

<img src="/files/CYBER60/keyboard-layout.png">

```
["~\n`","!\n1","@\n2","#\n3","$\n4","%\n5","^\n6","&\n7","*\n8","(\n9",")\n0","_\n-","+\n=",{w:2},"Backspace"],
[{w:1.5},"Tab","Q","W","E","R","T","Y","U","I","O","P","{\n[","}\n]",{w:1.5},"|\n\\"],
[{w:1.75},"Caps Lock","A","S","D","F","G","H","J","K","L",":\n;","\"\n'",{w:2.25},"Enter"],
[{w:2.25},"Shift","Z","X","C","V","B","N","M","<\n,",">\n.","?\n/",{w:2.75},"Shift"],
[{w:1.5},"Ctrl",{w:1.25},"Win",{w:1.5},"Alt",{a:7,w:2.75},"",{w:1},"",{a:7,w:2.75},"",{a:4,w:1.5},"AltGr",{w:1.25},"Win",{w:1.5},"Ctrl"]
```

## ZMK Firmware

Documentation is availble <a href = "https://zmk.dev/docs">here</a> 


### Pointing Device Support

Pointing devices are not currently not supported in the release version of ZMK, however, the feature branch from <a href="https://github.com/urob">urob</a> has an implementation pending PR.

While it is generally possible to integrate a pointing device with the MCU, there are not enough free _accessible_ pins to do so. Three GPIO pins are needed. Since I will not be using a rotary encoder, `ROT_A` and `ROT_B` provide two pins. The third will need to be repurposed from another component. 4pplet recommends using the buzzer or caplock LED, however, modifications are necessary.

<img src="/files/CYBER60/4pplet_email.png">

Instead, I will implement pointing mouse emulation via IJKL keys.

- Update `west.yml` to point to feature branch <a href = "https://www.reddit.com/r/ErgoMechKeyboards/comments/w39hpt/zmk_users_how_to_add_mouse_keys/igv6cex/
https://github.com/urob/zmk-config/tree/main/config">(Reference)</a>
- Mouse emulation is not currently supported in GUI keyboard editing tools, so has to be manually added to keymap file
- <a href = "https://deploy-preview-778--zmk.netlify.app/docs/behaviors/mouse-emulation/">Draft ZMK documenation</a>
- https://rfong.github.io/rflog/2021/10/26/r61-trackpoint-pt2/
- https://github.com/manna-harbour/crkbd/tree/master/trackpoint#driver-board


# Inspiration

While gasket-mount case constructions are very popular right now, due to allowing flex in the keyboard, I am not convinced about the value added. My case is designed as a tray-mount. Construction of the case uses a sandwitch design which means that the overall vertical thickness of the case is made up of several layers. The main body of the case will be constructed using stacked leather. This is a technique used in the construction of handles for tools and knives. The process involves compressing leather and then shaping it. This technique is also found in shoemaking. The end result is comparable to wood.

<img src="/files/CYBER60/Stackedleather.png">

For the overall case design, I'm going for: thick bezels, hard eges, angular. Some references:

Keychron
<img src = "/files/CYBER60/keychronq4.png">

PBTfans Retro Dark Light keycaps
<img src="/files/CYBER60/large_10314_large_KBDPT17-3_1.jpg">

- Keychron <a href = "/files/CYBER60/keychronq1.png">(1)</a> 
- ZT60 <a href ="/files/CYBER60/ZT60.png">(1)</a>
- Poseidon Defender <a href="/files/CYBER60/Defender.png">(1)</a>
- Brutal V2 <a href= "/files/CYBER60/BrutalV2.png">(1)</a>






# Design

The body of the case consists of four layers:

| Layer                | Thickness           | Material |
|----------------------|---------------------|----------|
| Top plate            | 5mm                 | Metal    |
| Body                 | 7mm                 | Leather  |
| Transparent diffuser | 1/8"                | Acrylic  |
| Bottom plate         | 5mm                 | Metal    |
| Base (wedge)         | 11mm (at thickest)  | Metal    |


<img src="/files/CYBER60/Renders/overview1.png">

<img src="/files/CYBER60/Renders/overview2.png">

The most complicated piece is the base which provides the keyboard a 5-degree tilt.

<img src="/files/CYBER60/Renders/overview3.png">

## Layers

### Bottom Plate

The bottom plate is machined from a single sheet of 1/4" material down to 5mm.

On the top side:

<img src="/files/CYBER60/Renders/base1.png">

- PCB tray area recessed by 1mm
- 120mm x 40mm cutout for battery
- 4 countersuck holes for mounting the base
  - M3
  - Countersink diameter (6.30mm)
  - Drill through
- 6 tapped holes for attaching PCB
  - M2
  - Drill through

On the bottom side:

<img src="/files/CYBER60/Renders/base2.png">

- 1mm chamfer around the outer perimeter
- 12 countersunk holes for the body assembly
  - M2
  - Countersink diameter (4.40mm)
  - Drill through

### Mid Body

The body of the case consists of an acrylic layer (1/8") and stacked leather. Construction of the stacked leather is covered (here).

<img src="/files/CYBER60/Renders/mid1.png">

For the acrylic piece:

- 12 holes for the body assembly
  - M2
  - Clearance hole
  - Drill through

Note the overhang lip on the shorter side: the PCB sits on this surface. In the middle, the PCB is held up by with spacers.

### Top Plate

The top plate is machined from a single sheet of 1/4" material down to 5mm.

On the top side:

<img src="/files/CYBER60/Renders/top1.png">

- 1mm chamfer around the outer perimeter

On the bottom side:

<img src="/files/CYBER60/Renders/top2.png">

- 12 tapped holes for the body assembly
  - M2
  - Drilled 3mm (not visible from the top side)
 
### Wedge

The base is machined from a single sheet of 1/2" material. 

<img src="/files/CYBER60/Renders/wedge2.png">

I have no idea how this is to be done, how complicated it is, or if it is feasible. The general shape is a 5-degree wedge. The additional geometries are visual.

On the top side:

<img src="/files/CYBER60/Renders/wedge1.png">

- 15mm x 60mm cutout for the USB C daughterboard, at a depth of 8mm
- 4 tapped holes for mounting to the bottom plate
  - M3
  - Drilled 2.5mm

On the bottom side:

<img src="/files/CYBER60/Renders/wedge3.png">

- Slots for feet

## Assembly

<img src="/files/CYBER60/Renders/assembly1.png">

<img src="/files/CYBER60/Renders/assembly3.png">

<img src="/files/CYBER60/Renders/assembly4.png">



# Construction

## Leather Stack

General idea: https://www.instructables.com/Stacked-Leather-Knife-Handle/

The bottom plate and cutout of the PCB tray forms the mold in which to shape the leather. The cutout ensures that inside face is formed precisely.

<img src="/files/CYBER60/Renders/wetform3.png">

Wet leather pieces in the shape of the case are then fit between the top and bottom plate and compressed using threaded rods, washers and bolts. It is important to ensure that the leather is uniformly compressed.

Since the interior edge is constrained, the compressed leather will expand towards the outer side. When dry, the excess leather can be cut/sanded off indexed by the top and bottom plate. This should produce a perfectly flush finish.

The leather stack should then be disassembled, glued back together, and polished. 

<img src="/files/CYBER60/Renders/wetform1.png">

This is how the press assembly works.

<img src="/files/CYBER60/Renders/wetform2.png">





# Bill Of Materials















# etc etc scrap notes

For the metal and acrylic, each plate requires minimally 13"x5" of material.

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

- butt ton of screws, washers, etc

- USB C to JST connector
  - https://cannonkeys.com/products/unified-c4-daughterboard
  - <a href = "https://cannonkeys.com/products/unified-s1-daughterboard-and-molex-cable?pr_prod_strat=use_description&pr_rec_id=28807589f&pr_rec_pid=7087153021039&pr_ref_pid=7117023379567&pr_seq=uniform">Molex to JST cable</a>
  - https://cannonkeys.com/products/molex-and-jst-cables?variant=41098401972335"
