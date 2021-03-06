globals [pct-clean all-tiles]
breed [vacuums vacuum]
breed [chaosagents chaosagent]
chaosagents-own [speed]
vacuums-own [speed turn-angle turn-state turn-clockwise num-fwd-moves backtrack-counter backtrack-complete hang-time-counter ]

to setup
  clear-all

  create-vacuums 1 [
    set shape "ufo top"
    set color blue
    set size 4
    set heading 0
    set turn-angle 90
    set turn-state 0
    set turn-clockwise 0
    set num-fwd-moves 0
    set backtrack-counter 0
    set backtrack-complete false
    set hang-time-counter 0
  ]

  if (number-of-chaos-agents > 0)
  [
    create-chaosagents number-of-chaos-agents [
      set shape "Chaos Agent"
      set size 4
      set speed chaos-agent-speed
    ]
  ]

  init-floorplan
  init-agents
  reset-ticks
end

to go
  move-robot
  if (number-of-chaos-agents > 0) [move-chaos-agent]

  ; terminating conditions
  set pct-clean floor (count patches with [pcolor = green] * 100 / all-tiles)
  if pct-clean >= max-clean [ stop ]

  tick
end

to init-floorplan
  ; draw outside world border
  draw-rectangle min-pxcor min-pycor max-pxcor max-pycor red

  (ifelse
    floor-plan = "floor plan 1"                [ draw-floorplan-1 ]
    floor-plan = "floor plan 2"                [ draw-floorplan-2 ]
    floor-plan = "floor plan 3"                [ draw-floorplan-3 ]
  )

  if furniture-enabled = true
  [
    draw-furniture
  ]

  set all-tiles count patches with [pcolor = black]
end

to init-agents
  ask vacuums
  [
    move-to patch hub-x hub-y
    ;move-to one-of patches with [pcolor = black]
    pen-down
  ]

  ask chaosagents
  [
    move-to one-of patches with [pcolor = black]
  ]
end

to draw-floorplan-1
  ; horizontal dividers
  draw-rectangle -50  0    0  0   red

  ; vertical dividers
  draw-rectangle 0    20   0  50  red
  ; gap from y=0 to y=20
  draw-rectangle 0    -15  0  0   red
  ; gap from y=-35 to y=-15
  draw-rectangle 0    -50  0  -35 red

end

to draw-floorplan-2
  ; horizontal dividers
  draw-rectangle -50  0  -35  0   red
  ; gap from x=-35 to x=-15
  draw-rectangle -15  0    0  0   red

  ; vertical dividers
  draw-rectangle 0    -50  0  -35 red
  ; gap from y=-35 to y=-15
  draw-rectangle 0    -15  0  0   red

end

to draw-floorplan-3
  ; horizontal dividers
  draw-rectangle -50  0  -35  0   red
  ; gap from x=-35 to x=-15
  draw-rectangle -15  0   15  0   red
  ; gap from x=15 to x=35
  draw-rectangle 35   0   50  0   red

  ; vertical dividers
  draw-rectangle 0    -50  0  -35 red
  ; gap from y=-35 to y=-15
  draw-rectangle 0    -15  0  15  red
  ; gap from y=15 to y=35
  draw-rectangle 0    35   0  50  red
end

to draw-furniture
  draw-table
  draw-couch
  draw-chairs
  draw-tv
  draw-bed
end

to draw-table
  ; table is 6x18 starting at (-29,19)
  fill-rectangle -29 19 -24 36 gray
  ;fill-rectangle -19 - random 20 19 + random 5 -24 - random 10 26 + random 20 gray
end

to draw-couch
  ; couch is
  ; 6x18 starting at (9,24)
  fill-rectangle 9 24 14 41 gray
  ; 12x6 starting at (9,21)
  fill-rectangle 9 21 20 26 gray
end

to draw-chairs
  ask patch -33 32 [ask patches in-radius 2 [ set pcolor gray ] ]
  ask patch -33 22 [ask patches in-radius 2 [ set pcolor gray ] ]
  ask patch -20 32 [ask patches in-radius 2 [ set pcolor gray ] ]
  ask patch -20 22 [ask patches in-radius 2 [ set pcolor gray ] ]
end

to draw-tv
  fill-rectangle 45 25 45 36 gray
end

to draw-bed
  fill-rectangle -49 -34 -24 -17 gray
end

to fill-rectangle [startX startY stopX stopY new-color]
  ask patches with [
    (pxcor >= startX) and
    (pxcor <= stopX) and
    (pycor >= startY) and
    (pycor <= stopY)
  ]
  [set pcolor new-color ]
end

to draw-rectangle [startX startY stopX stopY new-color]
  ask patches with [
    (pxcor = startX) or (pxcor = stopX)
  ][
    if (pycor >= startY) and (pycor <= stopY) [set pcolor new-color]
  ]

  ask patches with [
    (pycor = startY) or (pycor = stopY)
  ][
   if (pxcor >= startX) and (pxcor <= stopX) [ set pcolor new-color ]
  ]

end

to move-robot
  ask vacuums
  [
    set speed vacuum-speed
    ; check for hangtime
;    ifelse (hang-time-counter > 0)
;    [ set hang-time-counter (hang-time-counter - 1) ]
;    ; no hangtime, do navigation
;    [
      ask patch-here [ set pcolor green ]

      ; check if stuck


      (ifelse
        ; turn-state=0 is when we are happily moving forward
        turn-state = 0 [
          ; check for obstacle
          ifelse (any? (patch-set patch-at dx dy) with [pcolor = red or pcolor = gray ]) or
                 (num-fwd-moves = 0) or
                 (any? (chaosagents-on patches in-cone 5 60))
          [
            ; obstacle detected, chage state to 'collision'
            set turn-state (turn-state + 1)
            ifelse (max-travel)
            [set num-fwd-moves (max-travel-distance)]
            [set num-fwd-moves (world-width + world-height)]
          ]
          [
            ; no obstacles, onward!
            forward speed
            if (max-travel) [ set num-fwd-moves (num-fwd-moves - 1) ]
            ; check for a banana and if so set hang time
;            if ([pcolor] of patch-here = violet)
;            [
;              ; Process Generator - Hang Time
;              set hang-time-counter random max-hang-time
;            ]
          ]
        ]

        ; turn-state=1, we detected a collision and take first turn
        turn-state = 1 [
          ifelse turn-clockwise = 1
          [set heading (heading + first-angle)]
          [set heading (heading - first-angle)]

          ( ifelse
            first-angle-adjust =  "constant" [
              ifelse turn-clockwise = 1
              [set heading (heading + adjustment-1 )]
              [set heading (heading - adjustment-1 )]
            ]
            first-angle-adjust =  "random"   [
              set heading (heading + random (adjustment-1 * 2) - adjustment-1)
            ]
          )

          set turn-state (turn-state + 1)
        ]

        ; turn state=2, we did a first turn, now look for any 'moving over' options
        turn-state = 2 [
          if (move-over-between-turns = "yes") or
              ((move-over-between-turns = "random %") and (random 1 > 0))
          [
            ; moving over at current speed, check for collisions
            ifelse any? (patch-set patch-at dx dy) with [pcolor = red or pcolor = gray ]
            [
              ; extra turn gets us unstuck from corners (where we fail to move over)
              if switch-left-right
              [ set heading (heading + 90 + random stuck-random-angle) ]
            ]
            [
              ; no obstacles, onward!
              forward speed
              ; check for a banana and if so set hang time
;              if ([pcolor] of patch-here = violet)
;              [
;                ; Process Generator - Hang Time
;                set hang-time-counter random max-hang-time
;              ]
            ]
          ]
          set turn-state (turn-state + 1)
        ]

        ; turn state=3, we moved over if necessary, now complete the final turn and go back to normal going forward.
        turn-state = 3 [
          ifelse turn-clockwise = 1
          [set heading (heading + second-angle)]
          [set heading (heading - second-angle)]

          ( ifelse
            second-angle-adjust =  "constant" [
              ifelse turn-clockwise = 1
              [set heading (heading + adjustment-2 )]
              [set heading (heading - adjustment-2 )]
            ]
            second-angle-adjust =  "random" [
              set heading (heading + random (adjustment-2 * 2) - adjustment-2)
            ]
          )


          if switch-left-right
          [
            ; reverse turning direction, and reset state tracker.
            ifelse turn-clockwise = 1 [set turn-clockwise 0][set turn-clockwise 1]
          ]
          set turn-state 0
        ]
      )
;    ]
  ]

end

to move-chaos-agent
  ask chaosagents
  [
    while [([pcolor] of patch-ahead 1 = red) or ([pcolor] of patch-ahead 1 = gray)]
    [
      ; look ahead for any red patches in the X direction
      if ([pcolor] of patch-ahead 1 = red) or ([pcolor] of patch-ahead 1 = gray)
      [
        set heading (- heading)
      ]
      ; look ahead for any red patches in the Y direction
      if ([pcolor] of patch-ahead 1 = red) or ([pcolor] of patch-ahead 1 = gray)
      [
        set heading (180 - heading)
      ]
      rt random 20 - 10                             ; Process Generator - Change Turn Angle
    ]

    forward speed
;    if (1 = (random max-chance-of-banana-peel))            ; Process Generator - Banana Peel
;    [
;        ask patch-here [ set pcolor violet ]
;    ]
;
;    if (1 = (random max-chance-of-cause-mess))                       ; Process Generator - Cause Mess
;    [
;      ask patches in-cone 5 60 with [pcolor = green]
;        [
;            set pcolor black
;        ]
;    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
396
10
1010
625
-1
-1
6.0
1
10
1
1
1
0
1
1
1
-50
50
-50
50
0
0
1
ticks
6.0

BUTTON
6
10
69
43
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
76
10
139
43
go
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
146
10
209
43
run
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
1022
255
1133
300
Percentage Clean
pct-clean
17
1
11

PLOT
1021
11
1366
250
Cleaning Progress
ticks
% clean
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot pct-clean"

CHOOSER
5
51
211
96
floor-plan
floor-plan
"floor plan 1" "floor plan 2" "floor plan 3"
0

SWITCH
6
101
210
134
furniture-enabled
furniture-enabled
0
1
-1000

SLIDER
5
196
210
229
vacuum-speed
vacuum-speed
0.05
2
1.0
.05
1
/ tick
HORIZONTAL

SLIDER
13
582
274
615
chaos-agent-speed
chaos-agent-speed
0.05
2
0.25
.05
1
/ tick
HORIZONTAL

TEXTBOX
247
55
348
83
Docking Location
11
0.0
1

CHOOSER
9
281
101
326
first-angle
first-angle
180 90 0 -90 -180
1

CHOOSER
12
415
104
460
second-angle
second-angle
90 0 -90
0

CHOOSER
106
282
217
327
first-angle-adjust
first-angle-adjust
"constant" "random"
0

CHOOSER
108
415
220
460
second-angle-adjust
second-angle-adjust
"constant" "random"
0

INPUTBOX
221
282
307
342
adjustment-1
15.0
1
0
Number

INPUTBOX
223
415
301
475
adjustment-2
0.0
1
0
Number

CHOOSER
12
352
183
397
move-over-between-turns
move-over-between-turns
"yes" "no" "random %"
1

SLIDER
116
239
320
272
max-travel-distance
max-travel-distance
5
100
50.0
5
1
NIL
HORIZONTAL

SWITCH
7
239
109
272
max-travel
max-travel
1
1
-1000

SLIDER
1141
257
1330
290
max-clean
max-clean
0
100
50.0
1
1
percent
HORIZONTAL

INPUTBOX
215
74
286
134
hub-x
49.0
1
0
Number

INPUTBOX
293
74
366
134
hub-y
5.0
1
0
Number

SWITCH
192
353
351
386
switch-left-right
switch-left-right
1
1
-1000

INPUTBOX
14
480
130
540
stuck-random-angle
5.0
1
0
Number

SLIDER
12
620
276
653
number-of-chaos-agents
number-of-chaos-agents
0
5
5.0
1
1
chaos agents
HORIZONTAL

TEXTBOX
23
176
173
194
Vacuum Behavior
11
0.0
0

TEXTBOX
29
561
179
579
Chaos Agent Behavior
11
0.0
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

chaos agent
false
1
Circle -2674135 true true 110 5 80
Polygon -2674135 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -1184463 true false 127 79 172 94
Polygon -955883 true false 195 90 240 150 225 180 165 105
Polygon -955883 true false 105 105 60 165 75 195 135 120
Line -2674135 true 120 30 105 0
Line -2674135 true 135 15 105 0
Line -2674135 true 165 15 195 0
Line -2674135 true 180 45 195 0

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tile brick
false
0
Rectangle -1 true false 0 0 300 300
Rectangle -7500403 true true 15 225 150 285
Rectangle -7500403 true true 165 225 300 285
Rectangle -7500403 true true 75 150 210 210
Rectangle -7500403 true true 0 150 60 210
Rectangle -7500403 true true 225 150 300 210
Rectangle -7500403 true true 165 75 300 135
Rectangle -7500403 true true 15 75 150 135
Rectangle -7500403 true true 0 0 60 60
Rectangle -7500403 true true 225 0 300 60
Rectangle -7500403 true true 75 0 210 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

ufo top
false
0
Circle -1 true false 15 15 270
Circle -16777216 false false 15 15 270
Circle -7500403 true true 75 75 150
Circle -16777216 false false 75 75 150
Circle -7500403 true true 60 60 30
Circle -7500403 true true 135 30 30
Circle -7500403 true true 210 60 30
Circle -7500403 true true 240 135 30
Circle -7500403 true true 210 210 30
Circle -7500403 true true 135 240 30
Circle -7500403 true true 60 210 30
Circle -7500403 true true 30 135 30
Circle -16777216 false false 30 135 30
Circle -16777216 false false 60 210 30
Circle -16777216 false false 135 240 30
Circle -16777216 false false 210 210 30
Circle -16777216 false false 240 135 30
Circle -16777216 false false 210 60 30
Circle -16777216 false false 135 30 30
Circle -16777216 false false 60 60 30

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
