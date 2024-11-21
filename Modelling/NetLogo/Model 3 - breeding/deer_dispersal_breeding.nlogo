;Issues

; step-length - linearly modelled - maybe not the best way to do it?

; Notes
;
; Running ticks until 3685 is approx equal to running from the first release date to the first of Jan 2024

extensions [
  gis ; Loading extra packages
  time
  csv
  profiler
]

globals [
  dt ; The date-time of the model
  lcover ; Landcover values
  slo ; Slope values
  outline ; Outline of corsica
  distance-rd ; Distance to road
  sites ; Release sites shp
  test_file ; Just a global variable for exporting the n-visit.asc file
  season ; tracks whether it's summer or winter -
  season-counter ; Counts how many 12 hours have passed, and therefore whether it's the next season (2 ticks a day, therefore swaps season after 365 ticks)
  focal-deer ; the deer currently being modelled
  ; step-distances ;  list of step distances for evaluation
  target-patches ; The target patches used for deciding which patches to move deer to

]

breed [
  deer a-deer ; Assigning deer as a breed (singlular and plural)
]
breed [
  release-sites release-site ; Release sites
]


patches-own [
  type-of-landcover ; The type of landcover
  slope-value ; The slope
  distance-to-road ; The distance of every patch to the nearest significant road
  land ; are the patches on land?
  movement-prob ; for each deer and each tick, the probability said deer will move to the patch
  n-visits ; Number of deer visiting each patch
]

deer-own [
  sex-of-deer ; Each deer is assigned a sex
  prior-patch ; For calculating step distances
  home-range-patches ; List of patches representing an individuals home range
  release-site-x ; x coords of release site
  release-site-y ; y coords of release site

  offspring ; Variable for if the mother has offspring
  mother ; Who ID for mother deer, to follow
  independence-countdown ; A countdown for independence for offspring
  mature ; Whether a deer is mature or not - and thus whether or not they can breed
]

release-sites-own [
  sex_deer ; The sex of the deer released from this site (different beacuse it's a different variable assoicated with the patch)
  time ; The time (in ticks) the deer is to be released - again calculated with lubridates assistance so should be accurate!
]

to setup

  clear-all ; Clears everything

  set dt time:create-with-format "16-12-2015 10:00:00" "dd-MM-yyyy HH:mm:ss"
  set season "winter"

  ; Patches
  ;
  ; Note that setting the coordinate system here is optional, as
  ; long as all of your datasets use the same coordinate system.

  ; Read in the spatial data.
  set lcover gis:load-dataset "landcover.asc" ; Loading the rasters and assigning them to global variables
  set slo gis:load-dataset "slope.asc"
  set distance-rd gis:load-dataset "distance.asc"


  ; make each raster cell = patch in NetLogo
  let width floor (gis:width-of lcover / 2)
  let height floor (gis:height-of lcover / 2)
  resize-world (-1 * width ) width (-1 * height ) height

  ; define your patch size in pixels (makes your world size bigger/smaller in the Interface):
  set-patch-size 1

  ; Set the world envelope to the union of all of our dataset's envelopes
  gis:set-world-envelope (gis:envelope-union-of (gis:envelope-of distance-rd) (gis:envelope-of lcover) (gis:envelope-of slo))

  ; Applying global raster values to patch values (gis:apply-raster global patch)
  gis:apply-raster slo slope-value
  gis:apply-raster lcover type-of-landcover
  gis:apply-raster distance-rd distance-to-road

  ; Modifying patches (see below comments)
  ask patches [
    ifelse type-of-landcover >= 0 [set land "yes"] [set land "no"] ; Assigning a patch variable to identify if the patch is land or water (used later)
    ifelse (slope-value <= 0) or (slope-value >= 0) [ ; A known 'bug' with the GIS extension assigns patches without a value as 'NaN' - this replaces those with '0'
 ; do nothing
    ] [
      set slope-value 0 ; If above code is not met (i.e., it's NaN) then replaces with 0
    ]
  ]



  ; Assigning landcover values
  ask patches [

    (ifelse type-of-landcover = 1 [set type-of-landcover "artificial"]
      type-of-landcover = 2 [set type-of-landcover  "agricultural"]
      type-of-landcover = 3 [set type-of-landcover  "forest"]
      type-of-landcover = 4 [set type-of-landcover  "scrub"]
      type-of-landcover = 5 [set type-of-landcover  "bare"]
      type-of-landcover = 6 [set type-of-landcover "wetlands"]
      [set land "no"]
    )

  ]


  ; set step-distances []


  ; Create release points as turtles
  set sites gis:load-dataset "new_release_sites_for_NetLogo.shp"
  gis:create-turtles-from-points sites release-sites [set shape "circle"]


  reset-ticks ; Sets the tick counter to 0

end



to go

  ask release-sites [
    if time = ticks [ hatch-deer 1 [
      set sex-of-deer [sex_deer] of myself
      set home-range-patches []
      set home-range-patches fput patch-here home-range-patches
      set release-site-x xcor
      set release-site-y ycor
      set mother "none" ; No mother
      set offspring "no" ; No offspring at start
      set mature "yes" ; Can breed
    ]]
  ]

  ask deer [ ifelse pen-down? [pen-down][pen-up] ] ; Record pen marks or not

  birth ; Deer birth procedure
  move-adult ; deer move procedure
  move-offspring ; offspring move
  death ; Deer death procedure

  ;Exporting a visit map every 5 years from release until 2050
  if time:get "day" dt = 16 and time:get "month" dt = 12 and time:get "year" dt = 2020 and time:get "hour" dt = 10 [export-visit-map]
  if time:get "day" dt = 16 and time:get "month" dt = 12 and time:get "year" dt = 2025 and time:get "hour" dt = 10 [export-visit-map]
  if time:get "day" dt = 16 and time:get "month" dt = 12 and time:get "year" dt = 2030 and time:get "hour" dt = 10 [export-visit-map]
  if time:get "day" dt = 16 and time:get "month" dt = 12 and time:get "year" dt = 2035 and time:get "hour" dt = 10 [export-visit-map]
  if time:get "day" dt = 16 and time:get "month" dt = 12 and time:get "year" dt = 2040 and time:get "hour" dt = 10 [export-visit-map]
  if time:get "day" dt = 16 and time:get "month" dt = 12 and time:get "year" dt = 2045 and time:get "hour" dt = 10 [export-visit-map]
  if time:get "day" dt = 16 and time:get "month" dt = 12 and time:get "year" dt = 2050 and time:get "hour" dt = 10 [export-visit-map]


  set dt time:plus dt 12 "hours"

  if time:get "day" dt = 15 and time:get "month" dt = 4 [set season "summer"]
  if time:get "day" dt  = 15 and time:get "month" dt = 10  [set season "winter"]

  tick-advance 1 ; Add 1 onto the tick counter



  update-plots ; Updates any plots on the interface


end

; Sub-models
;
;

to birth

  ask deer with [sex-of-deer = "female" and offspring = "no" and mature = "yes"] [ ; For female deer which do not have offspring
    let rand-number random-float 1
    if rand-number > (1 - annual-birth-prob) ^ (1 / 730.5) [
      set offspring "yes"
      hatch 1 [
        ifelse random 2 = 0 [set sex-of-deer "male"][set sex-of-deer "female"]
        set mature "no" ; Means that the offspring won't reproduce - they're not mature
        set prior-patch patch-here
        set mother [who] of myself
        set offspring "no" ; Has no offspring
        set release-site-x xcor
        set release-site-y ycor
        ifelse random 2 = 0 [ set independence-countdown 730 ][ set independence-countdown 731 ] ; Average of about a years worth of 12 hour gaps
    ] ]
  ]

end


; Deer movement procedure
to move-adult

  ask deer with [mother = "none" and mature = "yes"]  [ ; Asking the deer (this ask deer individually in a random order) who is mature and independent of a mother

    set focal-deer self ; Sets itself as a focal deer (I need to do this for some code below)

    ask patch-here [ ; The deer has to ask the patch it is situated on so that the code below works (i.e., the patch the deer is on asks the other patches in a set radius).

      set target-patches other patches in-radius max-step-distance with [land = "yes"] ; creates an agentset of land patches within the max-step distance

      ask target-patches [ ; Asks these 'target patches'

        set movement-prob calculate-movement-probability ; ...to calculate the probability for the focal deer to move towards it

      ]

      let total-movement-prob (sum [movement-prob] of target-patches) ; Finding the sum of the probability for all considered patches for that deer

      ask target-patches [ ; Ask these patches...

        set movement-prob movement-prob / total-movement-prob ; ... to scale their probabilities to add to one

      ]
    ]

    move-deer-based-on-probability ; Select a patch to move to based on these probabilities

    ;let distance-moved (distance prior-patch)
    ;set step-distances fput distance-moved step-distances
    ;set prior-patch patch-here

  ]


end




to move-offspring

  ask deer with [independence-countdown > 0 and offspring = "no"] [
    face a-deer ([mother] of self)
    move-to a-deer ([mother] of self)
    set independence-countdown independence-countdown - 1
    ; For the next few lines - saying 'if the distance between my current location and my mums release site/centre of home range is > distance between my release site/home range centre and my mums...update my home range centre to the new one, because it's further away from mums centre of home range without being outside it
    if distancexy [release-site-x] of a-deer ([mother] of self) [release-site-y] of a-deer ([mother] of self) > (([release-site-x] of a-deer ([mother] of self) - [release-site-x] of self) ^ 2 + ([release-site-y] of a-deer ([mother] of self) - [release-site-y] of self) ^ 2 ) ^ 0.5 [
      set release-site-x xcor
      set release-site-y ycor
    ]

    if independence-countdown <= 0 [
      ask a-deer ([mother] of self) [set offspring "no"] ; Mother can breed again
      set offspring "no" ; Ready to breed
      set mother "none" ; No mother anymore
      set mature "yes" ; Is now a mature deer and can breed
    ]
  ]
end




to death

end



; Sub-prodecures and reporters
;
;
;
;
;
;
;
;
;
;
;
;
;


to-report calculate-movement-probability

  ; Let assigns a temporary variable only for this run - only for variables which aren't immediately obtainable from the patch variables
  ;let step-length  log (distance myself) e; Assigns a patches distance (in m) to the focal deer to a temp variable
  ;let turning-angle cos (subtract-headings (towards myself - 180) ([heading] of focal-deer))  ; Calculates the minimum angle that the deer heading needs to turn by to reach the patch heading, and assigns it to a temp variable
  ;let sex [sex-of-deer] of focal-deer ; Assigning sex as the sex of the deer in question
  let dist-from-release distancexy [release-site-x] of focal-deer [release-site-y] of focal-deer



; Converting beta values (with se uncertainty) to probabilities for each patch
  report exp (

    ((random-normal runresult (word "beta-" type-of-landcover) runresult (word "se-" type-of-landcover)) * 1 ) + ; Effect of landcover

    ((random-normal beta-slope se-slope) * slope-value ) + ; Effect of slope

    ((random-normal beta-distance-to-road se-distance-to-road) * distance-to-road ) + ; Effect of distance to road

    ((random-normal beta-step-length se-step-length) * ln (distance myself) ) + ; Effect of distance to patch (step-length)

    ((random-normal beta-turning-angle se-turning-angle) * cos (subtract-headings (towards myself - 180) ([heading] of focal-deer)) ) + ; Effect of turning angle to patch

    ((random-normal beta-distance-from-release se-distance-from-release) * dist-from-release) + ; Incorporating the distance of each patch from a deers release point

    ((random-normal runresult (word "beta-" type-of-landcover ":step-length") runresult (word "se-" type-of-landcover ":step-length")) * 1 * ln (distance myself) ) + ; Interaction between landcover and step length

    ((random-normal beta-distance-to-road:turning-angle se-distance-to-road:turning-angle) * distance-to-road * cos (subtract-headings (towards myself - 180) ([heading] of focal-deer)) ) + ; Interaction between distance to road and turning angle

    ((random-normal runresult (word "beta-" type-of-landcover ":turning-angle") runresult (word "se-" type-of-landcover ":turning-angle")) * 1 * cos (subtract-headings (towards myself - 180) ([heading] of focal-deer))  ) + ; The interaction between landcover and turning angle

    ((random-normal runresult (word "beta-slope:" season) runresult (word "se-slope:" season)) * 1 * slope-value) + ; The interaction between slope and season

    ((random-normal runresult (word "beta-distance-to-road:" season) runresult (word "se-distance-to-road:" season)) * 1 * distance-to-road) + ; The interaction between distance to road and season

    ((random-normal beta-slope:step-length se-slope:step-length) * slope-value * ln (distance myself)) + ; The interaction between slope and step-length

    ((random-normal runresult (word "beta-" type-of-landcover ":distance-to-road") runresult (word "se-" type-of-landcover ":distance-to-road")) * 1 * distance-to-road ) + ; The interaction between landcover and distance to road

    ((random-normal beta-slope:turning-angle se-slope:turning-angle) * slope-value * cos (subtract-headings (towards myself - 180) ([heading] of focal-deer)) ) + ; Interaction between slope and turning-angle

    ((random-normal runresult (word "beta-" type-of-landcover ":step-length:" [sex-of-deer] of focal-deer ":" season) runresult (word "se-" type-of-landcover ":step-length:" [sex-of-deer] of focal-deer ":" season)) * 1 * ln (distance myself) ) ; Interaction between landcover:step-length:sex:season


  )


end




to move-deer-based-on-probability; Moves deer to a new patch based on the calculated probabilities

  let r random-float 1 ; Random threshold at which the patch will be selected
  let cumulative-probability 0 ; Sets the cumulative probability
  let selected-patch nobody ; Sets the selected patch as nobody

  ask target-patches [ ; Only asking patches the deer could move to - done at a patch level similar to the move procedure so that 'other' works correctly
    set cumulative-probability cumulative-probability + movement-prob ; Adds on the movement probability - a higher probability means more likely to pass the r threshold
    if (selected-patch = nobody and r < cumulative-probability) [ ; If it does pass the threshold AND a patch hasn't already been selected (I.e., it's the first time the threshold is passed)...
      set selected-patch self ; ...selects this patch to move towards
      stop
    ]
  ]


  ifelse selected-patch != nobody [ ; If a patch is selected
    while [patch-here != selected-patch] [
      let current-patch patch-here ; While the patch the focal deer is on is not the selected patch...
      face selected-patch ; ...the focal deer faces the selected patch...
      forward 1 ; ...and moves one patch towards it (i.e., 100m here)
      if patch-here != current-patch [ask patch-here [patch-count]] ; Each time, the patch the deer is on adds 1 onto it's n-visit variable BUT doesn't doublecount if it doesn't move off the patch
      if patch-here != current-patch and offspring = "yes" [ask patch-here [patch-count]] ; Each time, the patch the deer is on adds 1 onto it's n-visit variable for an offspring BUT doesn't doublecount if it doesn't move off the patch
      set home-range-patches fput patch-here home-range-patches ; Add the patch to the deers home range
    ]
  ] [
    error (word "Deer has not moved from " patch-here " and sum of patches surrounding the focal deer is " cumulative-probability); If a deer doesn't move there's an error message - currently this is not showing :)
  ]



end



to patch-count

  set n-visits n-visits + 1  ; Adds on one to the

end





to export-visit-map

  ask one-of patches [
    set test_file gis:patch-dataset n-visits ; Collects the n-visit variables from the patches
  ]
  gis:store-dataset test_file (word "output_maps/n-visits_" behaviorspace-run-number) ; Exports the n-visit raster as an .asc raster

end

to export-home-range-sizes

  ask deer [ set home-range-patches remove-duplicates home-range-patches ] ; Double checks that duplicate patches are removed
  csv:to-file (word "Results/home-range-sizes_" behaviorspace-run-number ".csv") [ (list who (length home-range-patches)) ] of deer

end




to colour-by-slope

  gis:paint slo 0 ; To colour the map by slope value

end


to colour-by-landcover

  clear-drawing

  ask patches [ ; To colour the patches by landcover

    if type-of-landcover = "artificial" [set pcolor 5]
    if type-of-landcover = "agricultural" [set pcolor 25]
    if type-of-landcover = "forest" [set pcolor 65]
    if type-of-landcover = "scrub" [set pcolor 45]
    if type-of-landcover = "bare" [set pcolor 35]
    if type-of-landcover = "wetlands" [set pcolor 85]

  ]

end

to colour-by-distance-to-road

  gis:paint distance-rd 0 ; To colour the patches by distance to road.

end


to colour-by-n-visits

  gis:paint n-visits 0

end



; Profiling
;
;
;
;
;
;
;
;

to profile

  profiler:reset         ;; clear the data
  setup                  ;; set up the model
  profiler:start         ;; start profiling
  repeat 300 [ go ]       ;; run something you want to measure
  profiler:stop          ;; stop profiling
  print profiler:report  ;; view the results
  profiler:reset         ;; clear the data

end
@#$#@#$#@
GRAPHICS-WINDOW
412
17
1523
1785
-1
-1
1.0
1
10
1
1
1
0
0
0
1
-551
551
-879
879
1
1
1
ticks
30.0

BUTTON
29
29
95
62
Set-up
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
114
30
177
63
Go
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

BUTTON
114
72
177
105
step
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
29
193
179
226
Colour by landcover
colour-by-landcover
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
7
118
117
151
pen-down?
pen-down?
1
1
-1000

BUTTON
20
234
190
267
Colour by distance to road
colour-by-distance-to-road
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
24
393
196
426
max-step-distance
max-step-distance
1
100
86.5
0.1
1
NIL
HORIZONTAL

INPUTBOX
21
919
111
979
beta-distance-to-road
-3.16E-4
1
0
Number

INPUTBOX
122
918
205
978
se-distance-to-road
4.368E-5
1
0
Number

INPUTBOX
22
982
111
1042
beta-step-length
-0.3101
1
0
Number

INPUTBOX
122
980
206
1040
se-step-length
0.1107
1
0
Number

INPUTBOX
23
496
112
556
beta-artificial
0.0
1
0
Number

INPUTBOX
124
498
208
558
se-artificial
0.0
1
0
Number

INPUTBOX
23
562
113
622
beta-bare
0.5212
1
0
Number

INPUTBOX
124
564
208
624
se-bare
0.1051
1
0
Number

INPUTBOX
23
629
113
689
beta-forest
0.2462
1
0
Number

INPUTBOX
122
631
208
691
se-forest
0.09768
1
0
Number

INPUTBOX
23
694
114
754
beta-scrub
0.3444
1
0
Number

INPUTBOX
121
696
209
756
se-scrub
0.1004
1
0
Number

INPUTBOX
23
430
114
490
beta-agricultural
0.3253
1
0
Number

INPUTBOX
121
429
206
489
se-agricultural
0.1091
1
0
Number

INPUTBOX
11
1257
166
1317
beta-artificial:step-length
0.0
1
0
Number

INPUTBOX
174
1257
329
1317
se-artificial:step-length
0.0
1
0
Number

INPUTBOX
10
1193
165
1253
beta-agricultural:step-length
0.6001
1
0
Number

INPUTBOX
175
1191
330
1251
se-agricultural:step-length
0.1164
1
0
Number

INPUTBOX
10
1324
165
1384
beta-bare:step-length
0.5453
1
0
Number

INPUTBOX
174
1323
329
1383
se-bare:step-length
0.1131
1
0
Number

INPUTBOX
11
1387
166
1447
beta-forest:step-length
0.5917
1
0
Number

INPUTBOX
174
1387
329
1447
se-forest:step-length
0.1103
1
0
Number

INPUTBOX
11
1451
166
1511
beta-scrub:step-length
0.4643
1
0
Number

INPUTBOX
175
1452
330
1512
se-scrub:step-length
0.1109
1
0
Number

BUTTON
273
32
389
65
Export visit map
export-visit-map
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
184
31
259
64
Clear all
clear-all
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
48
277
160
310
Colour by slope
colour-by-slope
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
22
852
112
912
beta-slope
0.02176
1
0
Number

INPUTBOX
124
855
206
915
se-slope
0.001808
1
0
Number

INPUTBOX
14
1043
119
1103
beta-turning-angle
-2.262
1
0
Number

INPUTBOX
126
1044
221
1104
se-turning-angle
0.1027
1
0
Number

INPUTBOX
13
1706
168
1766
beta-agricultural:turning-angle
-0.1254
1
0
Number

INPUTBOX
178
1704
333
1764
se-agricultural:turning-angle
0.1084
1
0
Number

INPUTBOX
14
1769
169
1829
beta-artificial:turning-angle
0.0
1
0
Number

INPUTBOX
177
1769
332
1829
se-artificial:turning-angle
0.0
1
0
Number

INPUTBOX
14
1832
169
1892
beta-bare:turning-angle
0.7975
1
0
Number

INPUTBOX
178
1834
333
1894
se-bare:turning-angle
0.1042
1
0
Number

INPUTBOX
14
1895
169
1955
beta-forest:turning-angle
0.1875
1
0
Number

INPUTBOX
176
1898
331
1958
se-forest:turning-angle
0.1014
1
0
Number

INPUTBOX
11
1513
166
1573
beta-wetlands:step-length
-1.0E27
1
0
Number

INPUTBOX
174
1514
329
1574
se-wetlands:step-length
0.0
1
0
Number

INPUTBOX
14
1961
169
2021
beta-scrub:turning-angle
0.2917
1
0
Number

INPUTBOX
177
1961
332
2021
se-scrub:turning-angle
0.102
1
0
Number

INPUTBOX
14
2026
169
2086
beta-wetlands:turning-angle
-1.0E27
1
0
Number

INPUTBOX
175
2025
330
2085
se-wetlands:turning-angle
0.0
1
0
Number

INPUTBOX
14
2125
169
2185
beta-slope:step-length
-0.009516
1
0
Number

INPUTBOX
173
2126
328
2186
se-slope:step-length
8.122E-4
1
0
Number

INPUTBOX
12
2219
167
2279
beta-agricultural:distance-to-road
-1.454E-4
1
0
Number

INPUTBOX
173
2219
328
2279
se-agricultural:distance-to-road
3.755E-5
1
0
Number

INPUTBOX
14
2285
169
2345
beta-artificial:distance-to-road
0.0
1
0
Number

INPUTBOX
174
2284
329
2344
se-artificial:distance-to-road
0.0
1
0
Number

INPUTBOX
14
2349
169
2409
beta-bare:distance-to-road
-2.992E-5
1
0
Number

INPUTBOX
173
2347
328
2407
se-bare:distance-to-road
2.92E-5
1
0
Number

INPUTBOX
13
2415
168
2475
beta-forest:distance-to-road
2.366E-5
1
0
Number

INPUTBOX
173
2413
328
2473
se-forest:distance-to-road
2.881E-5
1
0
Number

INPUTBOX
12
2479
167
2539
beta-scrub:distance-to-road
2.56E-5
1
0
Number

INPUTBOX
173
2477
328
2537
se-scrub:distance-to-road
2.9E-5
1
0
Number

INPUTBOX
11
2543
166
2603
beta-wetlands:distance-to-road
-1.0E27
1
0
Number

INPUTBOX
172
2540
327
2600
se-wetlands:distance-to-road
0.0
1
0
Number

INPUTBOX
21
2941
176
3001
beta-slope:turning-angle
0.01336
1
0
Number

INPUTBOX
182
2942
337
3002
se-slope:turning-angle
0.001267
1
0
Number

INPUTBOX
428
1819
632
1879
beta-artificial:step-length:male:summer
0.5016
1
0
Number

INPUTBOX
427
1882
633
1942
beta-agricultural:step-length:male:summer
0.2533
1
0
Number

INPUTBOX
428
1946
634
2006
beta-bare:step-length:male:summer
-0.02799
1
0
Number

INPUTBOX
429
2010
634
2070
beta-forest:step-length:male:summer
0.1387
1
0
Number

INPUTBOX
430
2075
635
2135
beta-scrub:step-length:male:summer
0.1536
1
0
Number

INPUTBOX
430
2138
634
2198
beta-wetlands:step-length:male:summer
-1.0E27
1
0
Number

INPUTBOX
650
1818
855
1878
se-artificial:step-length:male:summer
0.4052
1
0
Number

INPUTBOX
651
1882
854
1942
se-agricultural:step-length:male:summer
0.0656
1
0
Number

INPUTBOX
648
1946
856
2006
se-bare:step-length:male:summer
0.04185
1
0
Number

INPUTBOX
648
2010
857
2070
se-forest:step-length:male:summer
0.03607
1
0
Number

INPUTBOX
649
2074
857
2134
se-scrub:step-length:male:summer
0.03102
1
0
Number

INPUTBOX
649
2140
859
2200
se-wetlands:step-length:male:summer
0.0
1
0
Number

INPUTBOX
927
1817
1145
1877
beta-artificial:step-length:female:summer
0.0
1
0
Number

INPUTBOX
926
1882
1145
1942
beta-agricultural:step-length:female:summer
0.0
1
0
Number

INPUTBOX
927
1945
1146
2005
beta-bare:step-length:female:summer
0.0
1
0
Number

INPUTBOX
926
2009
1146
2069
beta-forest:step-length:female:summer
0.0
1
0
Number

INPUTBOX
924
2073
1148
2133
beta-scrub:step-length:female:summer
0.0
1
0
Number

INPUTBOX
923
2140
1149
2200
beta-wetlands:step-length:female:summer
-1.0E27
1
0
Number

INPUTBOX
1162
1816
1380
1876
se-artificial:step-length:female:summer
0.0
1
0
Number

INPUTBOX
1162
1879
1379
1939
se-agricultural:step-length:female:summer
0.0
1
0
Number

INPUTBOX
1162
1941
1380
2001
se-bare:step-length:female:summer
0.0
1
0
Number

INPUTBOX
1162
2004
1380
2064
se-forest:step-length:female:summer
0.0
1
0
Number

INPUTBOX
1161
2067
1382
2127
se-scrub:step-length:female:summer
0.0
1
0
Number

INPUTBOX
1161
2132
1384
2192
se-wetlands:step-length:female:summer
0.0
1
0
Number

INPUTBOX
427
2307
631
2367
beta-agricultural:step-length:male:winter
0.1182
1
0
Number

INPUTBOX
426
2243
630
2303
beta-artificial:step-length:male:winter
-0.1581
1
0
Number

INPUTBOX
426
2376
630
2436
beta-bare:step-length:male:winter
-0.06209
1
0
Number

INPUTBOX
426
2440
631
2500
beta-forest:step-length:male:winter
-0.03215
1
0
Number

INPUTBOX
426
2505
630
2565
beta-scrub:step-length:male:winter
0.03264
1
0
Number

INPUTBOX
428
2574
630
2634
beta-wetlands:step-length:male:winter
-1.0E27
1
0
Number

INPUTBOX
651
2306
853
2366
se-agricultural:step-length:male:winter
0.08206
1
0
Number

INPUTBOX
651
2241
852
2301
se-artificial:step-length:male:winter
0.1632
1
0
Number

INPUTBOX
651
2372
853
2432
se-bare:step-length:male:winter
0.04024
1
0
Number

INPUTBOX
651
2436
853
2496
se-forest:step-length:male:winter
0.03729
1
0
Number

INPUTBOX
650
2500
853
2560
se-scrub:step-length:male:winter
0.03355
1
0
Number

INPUTBOX
649
2570
854
2630
se-wetlands:step-length:male:winter
0.0
1
0
Number

INPUTBOX
907
2306
1127
2366
beta-agricultural:step-length:female:winter
0.101
1
0
Number

INPUTBOX
906
2241
1126
2301
beta-artificial:step-length:female:winter
0.3451
1
0
Number

INPUTBOX
916
2375
1137
2435
beta-bare:step-length:female:winter
-0.0833
1
0
Number

INPUTBOX
915
2440
1137
2500
beta-forest:step-length:female:winter
0.00679
1
0
Number

INPUTBOX
914
2504
1135
2564
beta-scrub:step-length:female:winter
0.04294
1
0
Number

INPUTBOX
914
2567
1135
2627
beta-wetlands:step-length:female:winter
-1.0E27
1
0
Number

INPUTBOX
1143
2306
1351
2366
se-agricultural:step-length:female:winter
0.04976
1
0
Number

INPUTBOX
1141
2241
1352
2301
se-artificial:step-length:female:winter
0.1196
1
0
Number

INPUTBOX
1150
2376
1363
2436
se-bare:step-length:female:winter
0.03783
1
0
Number

INPUTBOX
1150
2438
1365
2498
se-forest:step-length:female:winter
0.01858
1
0
Number

INPUTBOX
1148
2503
1365
2563
se-scrub:step-length:female:winter
0.02468
1
0
Number

INPUTBOX
1148
2566
1365
2626
se-wetlands:step-length:female:winter
0.0
1
0
Number

MONITOR
315
121
394
166
Season
season
17
1
11

INPUTBOX
22
760
115
820
beta-wetlands
-1.0E27
1
0
Number

INPUTBOX
122
760
211
820
se-wetlands
0.0
1
0
Number

INPUTBOX
9
1605
164
1665
beta-distance-to-road:turning-angle
5.199E-5
1
0
Number

INPUTBOX
174
1608
329
1668
se-distance-to-road:turning-angle
1.859E-6
1
0
Number

INPUTBOX
4
1110
145
1170
beta-distance-from-release
-0.487
1
0
Number

INPUTBOX
150
1110
305
1170
se-distance-from-release
0.01676
1
0
Number

MONITOR
181
72
399
117
Date
dt
17
1
11

INPUTBOX
19
2792
174
2852
beta-distance-to-road:summer
1.88E-4
1
0
Number

INPUTBOX
177
2792
332
2852
se-distance-to-road:summer
4.557E-5
1
0
Number

INPUTBOX
18
2855
173
2915
beta-distance-to-road:winter
0.0
1
0
Number

INPUTBOX
178
2855
333
2915
se-distance-to-road:winter
0.0
1
0
Number

INPUTBOX
13
2629
168
2689
beta-slope:summer
-0.009514
1
0
Number

INPUTBOX
179
2630
334
2690
se-slope:summer
0.002181
1
0
Number

INPUTBOX
12
2694
167
2754
beta-slope:winter
0.0
1
0
Number

INPUTBOX
181
2694
336
2754
se-slope:winter
0.0
1
0
Number

BUTTON
46
343
167
376
Colour by n-visits
colour-by-n-visits
NIL
1
T
PATCH
NIL
NIL
NIL
NIL
1

MONITOR
274
205
376
250
Number of deer
count deer
17
1
11

MONITOR
327
258
386
303
Offspring
count deer with [mature = \"no\"]
17
1
11

SLIDER
226
392
398
425
annual-birth-prob
annual-birth-prob
0
1
0.65
0.01
1
NIL
HORIZONTAL

MONITOR
250
258
320
303
Mature deer
count deer with [mature = \"yes\"]
17
1
11

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

moose
false
0
Polygon -7500403 true true 196 228 198 297 180 297 178 244 166 213 136 213 106 213 79 227 73 259 50 257 49 229 38 197 26 168 26 137 46 120 101 122 147 102 181 111 217 121 256 136 294 151 286 169 256 169 241 198 211 188
Polygon -7500403 true true 74 258 87 299 63 297 49 256
Polygon -7500403 true true 25 135 15 186 10 200 23 217 25 188 35 141
Polygon -7500403 true true 270 150 253 100 231 94 213 100 208 135
Polygon -7500403 true true 225 120 204 66 207 29 185 56 178 27 171 59 150 45 165 90
Polygon -7500403 true true 225 120 249 61 241 31 265 56 272 27 280 59 300 45 285 90

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

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
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="test - 100 replications" repetitions="100" runMetricsEveryStep="false">
    <setup>clear-all
random-seed behaviorspace-run-number
setup</setup>
    <go>go</go>
    <postRun>export-visit-map
export-home-range-sizes</postRun>
    <timeLimit steps="3685"/>
    <metric>count deer ; all deer</metric>
    <metric>count deer with [mature = "yes"] ; adult deer</metric>
    <metric>count deer with [mature = "no"] ; offspring deer</metric>
    <metric>count patches with [n-visits &gt; 0] ; Occupied patches</metric>
    <enumeratedValueSet variable="beta-slope:turning-angle">
      <value value="0.01336"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-wetlands:turning-angle">
      <value value="-1.0E27"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-bare:step-length:female:summer">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-forest:step-length:male:summer">
      <value value="0.1387"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-scrub:turning-angle">
      <value value="0.102"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-forest:distance-to-road">
      <value value="2.881E-5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-slope:summer">
      <value value="-0.009514"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-forest:step-length">
      <value value="0.5917"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-scrub:step-length:male:summer">
      <value value="0.03102"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-forest:distance-to-road">
      <value value="2.366E-5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-slope:winter">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-distance-from-release">
      <value value="0.01676"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-scrub:step-length:female:winter">
      <value value="0.04294"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-bare:step-length:male:summer">
      <value value="-0.02799"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-distance-to-road:turning-angle">
      <value value="5.199E-5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-artificial">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-wetlands:step-length">
      <value value="-1.0E27"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pen-down?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-artificial:distance-to-road">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-agricultural:step-length:male:summer">
      <value value="0.0656"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-wetlands">
      <value value="-1.0E27"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-distance-to-road:summer">
      <value value="4.557E-5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-agricultural:step-length:male:winter">
      <value value="0.1182"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-agricultural:step-length:female:winter">
      <value value="0.04976"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-wetlands:step-length:female:summer">
      <value value="-1.0E27"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-distance-from-release">
      <value value="-0.487"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-forest:turning-angle">
      <value value="0.1875"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-artificial:turning-angle">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-wetlands:step-length">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-wetlands">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-wetlands:step-length:male:winter">
      <value value="-1.0E27"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-distance-to-road:winter">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-scrub:step-length:male:winter">
      <value value="0.03355"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-bare:turning-angle">
      <value value="0.7975"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-forest:step-length:female:summer">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-artificial:step-length:female:winter">
      <value value="0.3451"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-agricultural">
      <value value="0.3253"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-agricultural:step-length">
      <value value="0.6001"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-bare:step-length">
      <value value="0.1131"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-slope:step-length">
      <value value="8.122E-4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-agricultural:turning-angle">
      <value value="-0.1254"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-agricultural:step-length:male:winter">
      <value value="0.08206"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-scrub:turning-angle">
      <value value="0.2917"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-agricultural:step-length:female:summer">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-step-length">
      <value value="0.1107"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-turning-angle">
      <value value="-2.262"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-distance-to-road:winter">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-artificial:step-length:male:summer">
      <value value="0.4052"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-agricultural:step-length:female:summer">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-scrub:step-length:male:winter">
      <value value="0.03264"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-forest:step-length:female:winter">
      <value value="0.01858"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-artificial:turning-angle">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-scrub:step-length:female:winter">
      <value value="0.02468"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-bare:step-length:male:summer">
      <value value="0.04185"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-wetlands:turning-angle">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-forest:step-length">
      <value value="0.1103"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-distance-to-road">
      <value value="4.368E-5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-scrub">
      <value value="0.1004"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-wetlands:distance-to-road">
      <value value="-1.0E27"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-bare:distance-to-road">
      <value value="2.92E-5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-scrub:distance-to-road">
      <value value="2.56E-5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-artificial:step-length:female:winter">
      <value value="0.1196"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-scrub">
      <value value="0.3444"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-forest:step-length:female:winter">
      <value value="0.00679"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-distance-to-road">
      <value value="-3.16E-4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-agricultural:turning-angle">
      <value value="0.1084"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-artificial">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-bare:step-length:female:summer">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-wetlands:step-length:male:summer">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-forest:step-length:male:summer">
      <value value="0.03607"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-artificial:step-length:female:summer">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-slope">
      <value value="0.001808"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-wetlands:step-length:female:summer">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-slope">
      <value value="0.02176"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-forest">
      <value value="0.09768"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-agricultural:step-length">
      <value value="0.1164"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-agricultural:step-length:female:winter">
      <value value="0.101"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-artificial:step-length:male:summer">
      <value value="0.5016"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-scrub:step-length">
      <value value="0.4643"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-wetlands:step-length:male:summer">
      <value value="-1.0E27"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-bare">
      <value value="0.5212"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-artificial:step-length:male:winter">
      <value value="0.1632"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-distance-to-road:turning-angle">
      <value value="1.859E-6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-bare:step-length:male:winter">
      <value value="0.04024"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-wetlands:step-length:male:winter">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-forest:step-length:male:winter">
      <value value="0.03729"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-distance-to-road:summer">
      <value value="1.88E-4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-artificial:step-length">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-scrub:step-length:male:summer">
      <value value="0.1536"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-bare:turning-angle">
      <value value="0.1042"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-bare:step-length:male:winter">
      <value value="-0.06209"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-wetlands:step-length:female:winter">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-agricultural">
      <value value="0.1091"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-slope:turning-angle">
      <value value="0.001267"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-bare:step-length:female:winter">
      <value value="-0.0833"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-forest:step-length:male:winter">
      <value value="-0.03215"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-artificial:step-length:male:winter">
      <value value="-0.1581"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-bare:distance-to-road">
      <value value="-2.992E-5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-artificial:distance-to-road">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-slope:winter">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-forest">
      <value value="0.2462"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-bare:step-length:female:winter">
      <value value="0.03783"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-artificial:step-length:female:summer">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-step-length">
      <value value="-0.3101"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-agricultural:distance-to-road">
      <value value="3.755E-5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-scrub:step-length:female:summer">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-artificial:step-length">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-turning-angle">
      <value value="0.1027"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-step-distance">
      <value value="86.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-forest:turning-angle">
      <value value="0.1014"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-bare:step-length">
      <value value="0.5453"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-scrub:distance-to-road">
      <value value="2.9E-5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-forest:step-length:female:summer">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-wetlands:distance-to-road">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-wetlands:step-length:female:winter">
      <value value="-1.0E27"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-scrub:step-length">
      <value value="0.1109"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-bare">
      <value value="0.1051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-agricultural:step-length:male:summer">
      <value value="0.2533"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-agricultural:distance-to-road">
      <value value="-1.454E-4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-slope:summer">
      <value value="0.002181"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-scrub:step-length:female:summer">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-slope:step-length">
      <value value="-0.009516"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
