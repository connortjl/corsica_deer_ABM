
; Version 6 - this is a combination of bestmodel1 for all parameters, plus an unlogged distance2release/centre-of-HR of -0.5
; Included recording of step lengths and distance between mother-offspring HRs - step lengths are commented out for now to focus on speed

extensions [
  gis ; Loading extra packages
  time
  csv
  profiler
  table
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
  focal-deer ; the deer currently being modelled

  target-patches ; The target patches used for deciding which patches to move deer to


  hpc-stop ;should the hpc stop?
  run-id ;identifying shared runs

  dead-deer-who ; list of dead deer HR sizes
  dead-deer-HR ; list of dead deer HR sizes
  mother-offspring-HR-distances

  total-deer ; list of total deer at timepoints
  total-mature-deer ; list of mature deer at timepoints
  total-immature-deer ; list of immature deer at timepoints
  total-patches-visited ; total visited patches at timepoings

  distance-moved
  step-lengths ;  list of step distances for evaluation

  parameter-table
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
  age ; age of deer in 12 hour ticks
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

  setup-parameter-table ; Sets up the parameter table for speed gains (see below)

  set dt time:create-with-format "16-12-2015 10:00:00" "dd-MM-yyyy HH:mm:ss" ; Sets the date-time-year
  set season "winter" ; sets the season

  ; Patches
  ;
  ; Note that setting the coordinate system here is optional, as
  ; long as all of your datasets use the same coordinate system.

  ; Read in the spatial data.
  set lcover gis:load-dataset "landcover.asc" ; Loading the landcover rasters and assigning them to global variables
  set slo gis:load-dataset "slope.asc" ; Loading the slope rasters and assigning them to global variables
  set distance-rd gis:load-dataset "distance.asc" ; Loading the distance-to-road rasters and assigning them to global variables


  ; make each raster cell = patch in NetLogo
  let width floor (gis:width-of lcover / 2) ; sets 'width' as half of the raster width...
  let height floor (gis:height-of lcover / 2) ; ... and 'height' as half the raster height
  resize-world (-1 * width ) width (-1 * height ) height ; runs the raster from -width and -height to +width and +height, centering the raster around (0,0)

  ; define your patch size in pixels (makes your world size bigger/smaller in the Interface) - here 1 patch = 1 pixel = 1 ha
  set-patch-size 1

  ; Set the world envelope to the union of all of our dataset's envelopes
  gis:set-world-envelope (gis:envelope-union-of (gis:envelope-of distance-rd) (gis:envelope-of lcover) (gis:envelope-of slo))

  ; Applying global raster values to patch values (gis:apply-raster global patch)
  gis:apply-raster slo slope-value
  gis:apply-raster lcover type-of-landcover
  gis:apply-raster distance-rd distance-to-road

  ; Modifying patches
  ask patches [
    ifelse type-of-landcover >= 0 [set land "yes"] [set land "no"] ; Assigning a patch variable to identify if the patch is land or water (used later)
    ifelse (slope-value <= 0) or (slope-value >= 0) [ ; A known 'bug' with the GIS extension assigns patches without a value as 'NaN' - this replaces those with '0'
 ; do nothing
    ] [
      set slope-value 0 ; If above code is not met (i.e., it's NaN) then replaces with 0
    ]
  ]



  ; Assigning catagorical landcovers to patches
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


  ; Initialising lists for later processing
  set step-lengths []
  set dead-deer-who []
  set dead-deer-HR []
  set mother-offspring-HR-distances []

  set total-deer [] ; list of total deer at timepoints
  set total-mature-deer [] ; list of mature deer at timepoints
  set total-immature-deer [] ; list of immature deer at timepoints
  set total-patches-visited [] ; total visited patches at timepoings


  ; Create release points as agents
  set sites gis:load-dataset "new_release_sites_for_NetLogo.shp"
  gis:create-turtles-from-points sites release-sites [set shape "circle"]

  set run-id (round ((random-float 1) * 1000000)) ; Assigning each simulation a random ID - given the random floats they should be unique!

  reset-ticks ; Sets the tick counter to 0

  ;export-visit-map ; Sense check the export process - but was fine

end

to setup-parameter-table

  ; This is purely for speed gains - having the parameters in a table is much quicker (apparently)...

  set parameter-table table:make ; Creates a table

  let landcovers ["artificial" "agricultural" "forest" "scrub" "bare" "wetlands"]  ; List of relevant landcover types
  let seasons ["summer" "winter"]  ; List of all relevant seasons
  let sexes ["male" "female"]  ; List of sexes

  foreach landcovers [ lc -> ; For each lc value in the landcover list
    ; Store general landcover parameters from their values in the GUI into the parameter table
    table:put parameter-table (word "beta-" lc) (runresult (word "beta-" lc)) ; Makes a link in the parameter table between "beta-lc" and the value in the GUI
    table:put parameter-table (word "se-" lc) (runresult (word "se-" lc)) ; Same as above, for standard errors

    ; Store paratmeres for interactions between lc and step-length, turning angle, and distance to road. Exactly the same as above.
    table:put parameter-table (word "beta-" lc ":step-length") (runresult (word "beta-" lc ":step-length"))
    table:put parameter-table (word "se-" lc ":step-length") (runresult (word "se-" lc ":step-length"))
    table:put parameter-table (word "beta-" lc ":turning-angle") (runresult (word "beta-" lc ":turning-angle"))
    table:put parameter-table (word "se-" lc ":turning-angle") (runresult (word "se-" lc ":turning-angle"))
    table:put parameter-table (word "beta-" lc ":distance-to-road") (runresult (word "beta-" lc ":distance-to-road"))
    table:put parameter-table (word "se-" lc ":distance-to-road") (runresult (word "se-" lc ":distance-to-road"))

    ; Store step-length interaction terms per season and sex
    foreach seasons [ s -> ; For each s season
      foreach sexes [ sex -> ; For each sex
        table:put parameter-table (word "beta-" lc ":step-length:" s ":" sex) ; Stores the beta value for the four-way interaction between lc, step-length, season, and sex
                    (runresult (word "beta-" lc ":step-length:" s ":" sex))
        table:put parameter-table (word "se-" lc ":step-length:" s ":" sex) ; Stores the se value for the four-way interaction between lc, step-length, season, and sex
                    (runresult (word "se-" lc ":step-length:" s ":" sex))
      ] ; repeats for each sex...
    ] ; Repeats for each season...
  ] ; Finally repeats for each landcover type

  ; Store slope and road coefficients by season
  foreach seasons [ s -> ; For each s season
    table:put parameter-table (word "beta-slope:" s) (runresult (word "beta-slope:" s)) ; Stores beta the value for the interaction between slope and season
    table:put parameter-table (word "se-slope:" s) (runresult (word "se-slope:" s)) ; Stores the se value for the interaction between slope and season
    table:put parameter-table (word "beta-distance-to-road:" s) (runresult (word "beta-distance-to-road:" s)) ; Stores the beta value for the interaction  between distance2road and season
    table:put parameter-table (word "se-distance-to-road:" s) (runresult (word "se-distance-to-road:" s)) ; Stores the se value for the interaction between distance to road and season

  ]


end


to go

  set hpc-stop "no" ; Re-setting the stop condition for use on HPCs and other desktop computers (without needing the final tick number)

  ;Deer release submodel below
  ask release-sites [ ; Asks the release sites,..
    if time = ticks [ hatch-deer 1 [ ; ...if the tick number = their deer release time, to reintroduce a deer
      set sex-of-deer [ sex_deer ] of myself ; Deer has the assigned sex
      set age 731 ; All deer are assumed to be c.1 year old
      set home-range-patches [] ; initialises this deers HR patches
      set home-range-patches fput patch-here home-range-patches ; Sets the starting patch as a HR patch
      set release-site-x xcor ; Records the release site/centre of HR
      set release-site-y ycor ; Records the release site/centre of HR
      set mother "none" ; Deer has no mother
      set offspring "no" ; No offspring at start
      set mature "yes" ; The deer is mature (> 1year) and can breed
      set prior-patch patch-here
    ]]
  ]

  ask deer [ ifelse pen-down? [pen-down][pen-up] ] ; Record pen marks on GUI or not


  birth ; Deer birth procedure
  move-mature ; deer move procedure
  move-immature ; offspring move
  death ; Deer death procedure
  age-by-12hrs ; ages deer
  ; See below procedures for details


  ;Exporting a visit map every 5 years from release until 2040 - the only thing changing in the code below is the year
  if time:get "day" dt = 16 and time:get "month" dt = 12 and time:get "year" dt = 2020 and time:get "hour" dt = 10 [ ; If its 2020 on the 16th Dec...
    export-visit-map ; Exports a visit map
    set total-deer lput (count deer) total-deer ; Records the total number of deer
    set total-mature-deer lput (count deer with [mature = "yes"]) total-mature-deer ; Records the number of mature deer
    set total-immature-deer lput (count deer with [mature = "no"]) total-immature-deer ; Records the number of immature deer
    set total-patches-visited lput (count patches with [n-visits > 0]) total-patches-visited ; Records the total number of patches visited
  ]
  if time:get "day" dt = 16 and time:get "month" dt = 12 and time:get "year" dt = 2025 and time:get "hour" dt = 10 [ ; for 2025
    export-visit-map
    set total-deer lput (count deer) total-deer
    set total-mature-deer lput (count deer with [mature = "yes"]) total-mature-deer
    set total-immature-deer lput (count deer with [mature = "no"]) total-immature-deer
    set total-patches-visited lput (count patches with [n-visits > 0]) total-patches-visited
  ]
  if time:get "day" dt = 16 and time:get "month" dt = 12 and time:get "year" dt = 2030 and time:get "hour" dt = 10 [ ; for 2030
    export-visit-map
        set total-deer lput (count deer) total-deer
    set total-mature-deer lput (count deer with [mature = "yes"]) total-mature-deer
    set total-immature-deer lput (count deer with [mature = "no"]) total-immature-deer
    set total-patches-visited lput (count patches with [n-visits > 0]) total-patches-visited
  ]
  if time:get "day" dt = 16 and time:get "month" dt = 12 and time:get "year" dt = 2035 and time:get "hour" dt = 10 [ ; for 2035
    export-visit-map
        set total-deer lput (count deer) total-deer
    set total-mature-deer lput (count deer with [mature = "yes"]) total-mature-deer
    set total-immature-deer lput (count deer with [mature = "no"]) total-immature-deer
    set total-patches-visited lput (count patches with [n-visits > 0]) total-patches-visited
  ]
  if time:get "day" dt = 16 and time:get "month" dt = 12 and time:get "year" dt = 2040 and time:get "hour" dt = 10 [ ; for 2040
    export-visit-map
    export-home-range-sizes
    export-step-lengths
    export-mother-offspring-HR-distances
    set total-deer lput (count deer) total-deer
    set total-mature-deer lput (count deer with [mature = "yes"]) total-mature-deer
    set total-immature-deer lput (count deer with [mature = "no"]) total-immature-deer
    set total-patches-visited lput (count patches with [n-visits > 0]) total-patches-visited
    export-measures ; THIS TIME, the 'measures' are also exported - these are the total mature and immature deer, and patches visited for 2020 - 2040
    set hpc-stop "yes" ; Once 16/12/2040 is reached, the stop condition is activated
  ]


  if hpc-stop = "yes" [stop] ; The simulation stops if the stop condition is activated (see above)

  set dt time:plus dt 12 "hours" ; Advances the simulation internal date-time 12 hours

  if time:get "day" dt = 15 and time:get "month" dt = 4 [set season "summer"] ; If it's the 15th of April, summer starts
  if time:get "day" dt  = 15 and time:get "month" dt = 10  [set season "winter"] ; If it's the 15th October, winter starts

  tick-advance 1 ; Add 1 onto the tick counter


  update-plots ; Updates any plots on the GUI interfact


end ; The go procedure ends, this represents 1 'tick' or step of the ABM

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

; Sub-models (see above for when these are run during the go procedure


to birth

  ask deer with [sex-of-deer = "female" and mature = "yes"] [ ; For female mature deer
    let rand-number random-float 1 ; Assings a random float between 0 and 1 to the variable 'rand-number'

    ; Need to scale from annual to 12 hour scale. So take probability of not giving birth and take the 730.5th root.
    ; Then, if that random float is greater than the 12hr probability of not giving birth AND the mature female does not already have a young...
    if rand-number > (1 - annual-birth-prob) ^ (1 / 730.5) and offspring = "no" [
      set offspring "yes" ;...They give birth and set their offspring variable to yes
      hatch 1 [ ; Birth to 1 offspring
        ifelse random 2 = 0 [set sex-of-deer "male"][set sex-of-deer "female"] ; random sex of offspring (random 2 returns either 0 or 1)
        set mature "no" ; Means that the offspring won't reproduce - they're not mature
        set age 0 ; Age = 0 of newborns
        set mother [who] of myself ; Assigning the mother variable of the baby to it's mum's unique ID (myself here refers to the agent who asked this agent to do something i.e., the mother)
        set offspring "no" ; Has no offspring
        set release-site-x xcor ; initialises the release site of the baby, which here is used to track what will become the centre of their HR
        set release-site-y ycor ; as above line
        ifelse random 2 = 0 [ set independence-countdown 730 ][ set independence-countdown 731 ] ; Average of about a years worth of 12 hour gaps (would be 730.5 but cannot be half a tick)
        ;print (word sex-of-deer " deer " who " has been born with " offspring " offspring and " mature " maturity" ) ; Sense check
      ]
    ]
  ]

end


; Deer movement procedure
to move-mature ; Asking the adult mature deer to move

  ask deer with [mother = "none" and mature = "yes"]  [ ; Asking each individual deer (in a random order) who are mature and independent of a mother...

    set focal-deer self ; ... to set itself as a focal deer (I need to do this for some code below)

    ask patch-here [ ; The focal deer being simulated asks the patch it is situated on...

      set target-patches other patches in-radius max-step-distance with [land = "yes"] ; to create an agentset of land patches within the max-step distance (only patches can ask patches things, hence why the deer has to ask the patch first in the above line)

      ask target-patches [ ; Asks this 'target-patches' agentset...

        set movement-prob calculate-movement-probability ; ...to each individually calculate the probability for the focal deer to move towards it (see below procedure) - lots of patches = slow model

      ]

      let total-movement-prob (sum [movement-prob] of target-patches) ; Finding the sum of the probability for all target patches for that deer for the below code

      ask target-patches [ ; Ask these patches...

        set movement-prob movement-prob / total-movement-prob ; ... to scale their probabilities to add to one

      ]
    ]

    move-deer-based-on-probability ; Select a patch to move to based on these probabilities (see below procedure)

    ; Would estimate all step lengths - commented out for now to focus on speed

    ;ask patch-here [set distance-moved distance ([prior-patch] of myself)]
    ;set step-lengths fput distance-moved step-lengths
    ;set prior-patch patch-here

  ]

end




to move-immature ; Now, moving the immature deer with mothers

  ask deer with [independence-countdown > 0 and offspring = "no"] [ ; Those deer who are not independent - the offspring aspect here is potentially redundant (i.e., they'll all have offspring = "no")
    face a-deer ([mother] of self) ; Face their mother...
    move-to a-deer ([mother] of self) ; ...and jump to here
    set independence-countdown independence-countdown - 1 ; Drop the independence countdown by 1 unit
    ; For the next few lines - saying 'if the distance between my current location and my mums release site/centre of home range is > distance between my release site/home range centre and my mums...update my home range centre to the new one, because it's further away from mums centre of home range without being outside it
    ; there may be a neater way of doing it, but this appears to work fine
    if distancexy [release-site-x] of a-deer ([mother] of self) [release-site-y] of a-deer ([mother] of self) > (([release-site-x] of a-deer ([mother] of self) - [release-site-x] of self) ^ 2 + ([release-site-y] of a-deer ([mother] of self) - [release-site-y] of self) ^ 2 ) ^ 0.5 [
      set release-site-x xcor ; If the above is met, updates the x and y coords
      set release-site-y ycor ; see above line
    ]

    if independence-countdown <= 0 [ ; If the immature deer has survived long enough to become an adult...

      let change-x ([release-site-x] of self - [release-site-x] of a-deer ([mother] of self))
      let change-y ([release-site-y] of self - [release-site-y] of a-deer ([mother] of self))
      let a (change-x ^ 2 + change-y ^ 2) ^ 0.5 ; Pythag distance
      set mother-offspring-HR-distances fput a mother-offspring-HR-distances



      ask a-deer ([mother] of self) [
        set offspring "no"  ; The mother sets her offspring variable to "no", recording that her offspring has left her and she can breed again
      ]
      ; For the new mature deer
      set offspring "no" ; Ready to breed
      set mother "none" ; No mother anymore
      set mature "yes" ; Is now a mature deer and can breed
      ;print (word sex-of-deer " deer " who " is now independent: mature = " mature " offspring = " offspring) ; Sense check
    ]
  ]
end




to death

  ; Survival rates from 95-99% - so assume 97%

  ; Intrinsic senescence death
  ask deer [if age > max-lifespan-years * 730.5 [ ; for deer who's age is greater than the max lifespan in years (the *730.5 is to convert years to 12 hour ticks, the aging unit of the deer agents)
    ;set dead-deer-who fput who dead-deer-who ; Optional export of WHO ID and associated HR size
    ;set dead-deer-HR fput (length remove-duplicates home-range-patches) dead-deer-HR ; See above line
    ;print (word "deer " who " has died of old age") ; Sense check
    die ;kills deer agent and removes if from the model
  ]] ; Deer dies due to intrinsic senescnenc

  ; Extrinsic probabilistic death
  foreach sort deer [t -> ask t [ ; Asks deer individuals in the order they were created (which correlates to their age)
    let rand-number random-float 1 ; Selects a random float between 0 - 1
    if rand-number > (annual-survival-prob) ^ (1 / 730.5) [ ; If this float is greater than the annual survival probability scaled to a 12 hour scale...
      ;set dead-deer-who fput who dead-deer-who ; ...optional recording of who ID and HR size
      ;set dead-deer-HR fput (length remove-duplicates home-range-patches) dead-deer-HR ; See above line
      ;print (word "deer " who " has died of randomness") ; sense check
      die ; kills deer and removes it from the model
    ]

    if mature = "no" and a-deer ([mother] of self) = nobody [die] ; For offspring, if mum dies then they die too. Because they're ordered by WHO ID and because extrinsic death has been ran already, mum will always die first.

  ]]


end

to age-by-12hrs

  ask deer [set age age + 1] ; Just ages all surviving deer by 12 hrs.

end

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
; Sub-prodecures and reporters - these are typically ran in the above procedures (just mature movement I think) and at the timepoints highlighted in the go procedure (2020, 2025 etc)



to-report calculate-movement-probability
  ; This is a sub-procedure used by target-patches to estimate the probability the focal deer will move towards them
  ; This is done by calculating a relative intensity of usage from the SSF output, and then normalising in a later sub-procedure

  let step-length ln (distance myself)  ; Compute log step-length once - going from patch to patch not deer to patch, however should work better because deer not going to middle of patch so the distance is more accurate
  let turning-angle cos (subtract-headings (towards myself - 180) ([heading] of focal-deer))  ; Compute the minimum turning angle between the heading of the deer to the target-patch, and the current heading of the deer
  let dist-from-release (distancexy [release-site-x] of focal-deer [release-site-y] of focal-deer)  ; Compute the distance from the mature deers release point/centre of HR - NOT logged in this version
  let deer-sex [sex-of-deer] of focal-deer ; records the sex of the deer in question
  let road-dist ln distance-to-road ; logged distance2road

  ; Here, taking the needed parameter values from the parameter-table established in the set-up procedure - again, this is for speed to avoid redundant calls to the table or raw values in the GUI
  let beta-landcover table:get parameter-table (word "beta-" type-of-landcover)
  let se-landcover table:get parameter-table (word "se-" type-of-landcover)

  let beta-landcover-step table:get parameter-table (word "beta-" type-of-landcover ":step-length")
  let se-landcover-step table:get parameter-table (word "se-" type-of-landcover ":step-length")

  let beta-landcover-turn table:get parameter-table (word "beta-" type-of-landcover ":turning-angle")
  let se-landcover-turn table:get parameter-table (word "se-" type-of-landcover ":turning-angle")

  let beta-landcover-road table:get parameter-table (word "beta-" type-of-landcover ":distance-to-road")
  let se-landcover-road table:get parameter-table (word "se-" type-of-landcover ":distance-to-road")

  let beta-slope-season table:get parameter-table (word "beta-slope:" season)
  let se-slope-season table:get parameter-table (word "se-slope:" season)

  let beta-road-season table:get parameter-table (word "beta-distance-to-road:" season)
  let se-road-season table:get parameter-table (word "se-distance-to-road:" season)

  let beta-complex table:get parameter-table (word "beta-" type-of-landcover ":step-length:" season ":" deer-sex)
  let se-complex table:get parameter-table (word "se-" type-of-landcover ":step-length:" season ":" deer-sex)

  ; Computes probability using the formula exp(B1Z1 + B2Z2.....BxZx), where B is beta coefficients from the SSF, and Z are patch-level variables associated with each B value.
  let probs ; The below computes the 'B1Z1 + B2Z2.....BxZx' section of the above formula

  (random-normal beta-landcover se-landcover) + ; Just landcover
  (random-normal beta-slope se-slope) * slope-value + ; Just slope
  (random-normal beta-distance-to-road se-distance-to-road) * road-dist + ; just log distance2road (logged above)
  (random-normal beta-step-length se-step-length) * step-length + ; just log step length (logged above)
  (random-normal beta-turning-angle se-turning-angle) * turning-angle + ;just cos turning angle (cos'd earlier)
  (random-normal beta-distance-from-release se-distance-from-release) * dist-from-release + ; just distance2release NOT LOGGED (SEE VERSION NOTES)
  (random-normal beta-landcover-step se-landcover-step) * step-length + ; landcover x log step length (logged above)
  (random-normal beta-distance-to-road:turning-angle se-distance-to-road:turning-angle) * road-dist * turning-angle + ; log distance2road (logged above) x cos turning angle (cos'd above)
  (random-normal beta-landcover-turn se-landcover-turn) * turning-angle + ; landcover x cos turning angle (cos'd earlier)
  (random-normal beta-slope:step-length se-slope:step-length) * slope-value * step-length + ; log step length (logged above) x slope
  (random-normal beta-landcover-road se-landcover-road) * road-dist + ; landcover x log distance2road
  (random-normal beta-slope-season se-slope-season) * slope-value + ; slope x season
  (random-normal beta-road-season se-road-season) * road-dist + ; log distance2road x season
  (random-normal beta-slope:turning-angle se-slope:turning-angle) * slope-value * turning-angle + ; slope x cos turning angle (cos'd above)
  (random-normal beta-complex se-complex) * step-length ; sex x season x landcover x log step length (logged above)

report exp probs ; This exponates the above value to convert it to a relative intensity of use, and reports the actual number as an output of this sub-procedure

end




to move-deer-based-on-probability; Moves deer to a new patch based on the calculated probabilities - this is from the deer perspective (i.e., is within the ask deer [] code section)

  let r random-float 1 ; Random threshold at which the patch will be selected
  let cumulative-probability 0 ; Sets the cumulative probability
  let selected-patch nobody ; Sets the selected patch as nobody (NetLogo way of saying is no selected patch), for some speed gains and sense checks

  ask target-patches [ ; Only asking patches the focal deer could move to as above
    set cumulative-probability cumulative-probability + movement-prob ; Adds on the normalised movement probability - a higher probability means more likely to pass the r threshold, and the probabilities were normalised in the move-mature procedure
    if (selected-patch = nobody and r < cumulative-probability) [ ; If it does pass the threshold AND a patch hasn't already been selected (I.e., it's the first time the threshold is passed)...
      set selected-patch self ; ...selects this patch as the selected patch to move to
      stop ; Stops the procedure when a patch is picked - speed gain
    ]
  ]


  ifelse selected-patch != nobody [ ; If a patch is selected...
    while [patch-here != selected-patch] [ ; ...while the patch the focal deer is on is not the selected patch...
      let current-patch patch-here ; Used for avoiding double-counting below
      face selected-patch ; ...the focal deer faces the selected patch...
      forward 1 ; ...and moves one step towards it (i.e., 100m - the same scale as the patches)
      if patch-here != current-patch [ ; If the patch here is a new patch (i.e., the deer has moved off it's prior patch)...
        ask patch-here [patch-count] ; The deer asks the patch to add 1 onto it's n-visits variable
      ]
      if patch-here != current-patch and offspring = "yes" [ ; If the deer also has an offspring and has moved off it's prior patch
        ask patch-here [patch-count] ; The patch repeats the patch count procedure, which adds an additional 1 to it's n-visits variable
      ]
      set home-range-patches fput patch-here home-range-patches ; Add the patch to the deers home range (only the adults at this point)
      set home-range-patches remove-duplicates home-range-patches ; Removes duplicates - don't need duplicate patches and I'm hoping this may reduce list size and speed the procedure up
    ]
  ] [
    error (word "Deer has not moved from " patch-here " and sum of patches surrounding the focal deer is " cumulative-probability); If a deer doesn't move there's an error message - currently this is not showing :)
  ]

end



to patch-count ; The patch count procedure seen above

  set n-visits n-visits + 1  ; Adds on one to the patch count

end

;
;
;
;
; Output procedures

to export-visit-map ; Exporting the spatial visit maps

  ask one-of patches [
    set test_file gis:patch-dataset n-visits ; Collects the n-visit variables from the patches (have to ask one-of the patches to do this because it's at the patch level, but doesn't matter which one).
  ]
  gis:store-dataset test_file (word "output_maps/n-visits_" run-id "_ticks_" ticks) ; Exports the n-visit raster as an .asc raster to the output_maps folder

end

to export-home-range-sizes ; Exporting the HR sizes

  ask deer [ set home-range-patches remove-duplicates home-range-patches ] ; Double checks that duplicate patches are removed - possibly redundant but is a nice double check this is hapenning
  csv:to-file (word "Results/home-range-sizes_still_living_deer_" run-id ".csv") [ (list who (length home-range-patches)) ] of deer ; for still living deer, calculates their HR sizes by the number (length) of unique HR patches landed on
  ;csv:to-file (word "Results/home-range-sizes_dead_deer_" run-id ".csv") (list dead-deer-who dead-deer-HR) ; Optional, as above for dead deer - the number of HR patches (i.e., length home-range-patches) is calculated when the deer dies, so doesn't need doing here

end

to export-measures ; Exports pop size and patches explored, the each list is 5 long and has data from 2020-2040 in 5 year gaps

  csv:to-file (word "Results/measures_" run-id ".csv") (list total-deer total-mature-deer total-immature-deer total-patches-visited) ; Exports csv of the total deer pop size (split by mature and immature) and the total patches visited

end

to export-step-lengths

  csv:to-file (word "Results/step_lengths_" run-id ".csv") (list step-lengths) ; Exports csv of the total deer pop size (split by mature and immature) and the total patches visited

end

to export-mother-offspring-HR-distances

  csv:to-file (word "Results/mother_offspring_HR_distances_" run-id ".csv") (list mother-offspring-HR-distances) ; Exports csv of the total deer pop size (split by mature and immature) and the total patches visited

end

to colour-by-slope

  gis:paint slo 0 ; To colour the map by slope value - not used when simulating, only for earlier sense checks

end


to colour-by-landcover ; To colour the map by slope value - not used when simulating, only for earlier sense checks

  clear-drawing

  ask patches [ ; Asing patches to colour themselved by their landcover

    if type-of-landcover = "artificial" [set pcolor 5]
    if type-of-landcover = "agricultural" [set pcolor 25]
    if type-of-landcover = "forest" [set pcolor 65]
    if type-of-landcover = "scrub" [set pcolor 45]
    if type-of-landcover = "bare" [set pcolor 35]
    if type-of-landcover = "wetlands" [set pcolor 85]

  ]

end

to colour-by-distance-to-road

  gis:paint distance-rd 0 ; To colour the patches by distance to road - not used when simulating, only for earlier sense checks

end


to colour-by-n-visits

  gis:paint n-visits 0 ; Colour the map by n-visit value - not used when simulating, only for earlier sense checks. 0 here is the transparancy (i.e., not transparent)

end
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
;
;
; Profiling


to profile ; Procedure to speed check the model x runs, x = profile-tick-number

  profiler:reset         ;; clear the data
  setup                  ;; set up the model
  profiler:start         ;; start profiling
  repeat profile-tick-number [ go ]       ;; run something you want to measure
  profiler:stop          ;; stop profiling
  print profiler:report  ;; view the results
  profiler:reset         ;; clear the data

end
@#$#@#$#@
GRAPHICS-WINDOW
990
1551
2101
3319
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
0
0
1
ticks
30.0

BUTTON
35
45
98
78
NIL
setup\n
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
102
45
165
78
NIL
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

SWITCH
89
10
200
43
pen-down?
pen-down?
0
1
-1000

SLIDER
23
185
195
218
annual-birth-prob
annual-birth-prob
0
1
0.65
0.01
1
NIL
HORIZONTAL

SLIDER
24
222
196
255
max-step-distance
max-step-distance
0
100
26.0
1
1
NIL
HORIZONTAL

SLIDER
24
256
196
289
annual-survival-prob
annual-survival-prob
0
1
0.97
0.01
1
NIL
HORIZONTAL

SLIDER
23
291
195
324
max-lifespan-years
max-lifespan-years
0
50
14.0
1
1
NIL
HORIZONTAL

INPUTBOX
22
335
106
395
beta-slope
0.025518851504783
1
0
Number

INPUTBOX
112
335
189
395
se-slope
0.00183827938722221
1
0
Number

INPUTBOX
21
401
141
461
beta-distance-to-road
0.0135678807885984
1
0
Number

INPUTBOX
148
401
253
461
se-distance-to-road
0.0368058860666508
1
0
Number

INPUTBOX
20
465
143
525
beta-step-length
-0.277981115906896
1
0
Number

INPUTBOX
149
465
252
525
se-step-length
0.107406231285947
1
0
Number

INPUTBOX
18
529
143
589
beta-turning-angle
-2.78783818828574
1
0
Number

INPUTBOX
149
529
253
589
se-turning-angle
0.10743227235049
1
0
Number

INPUTBOX
19
595
160
655
beta-distance-from-release
-0.5
1
0
Number

INPUTBOX
165
595
294
655
se-distance-from-release
0.0
1
0
Number

INPUTBOX
15
663
199
723
beta-distance-to-road:turning-angle
0.148379056270227
1
0
Number

INPUTBOX
206
663
379
723
se-distance-to-road:turning-angle
0.00655605509221779
1
0
Number

INPUTBOX
13
729
135
789
beta-slope:step-length
0.00965050948976871
1
0
Number

INPUTBOX
141
729
252
789
se-slope:step-length
8.09133311833045E-4
1
0
Number

INPUTBOX
13
792
141
852
beta-slope:turning-angle
0.00904324706412455
1
0
Number

INPUTBOX
145
791
262
851
se-slope:turning-angle
0.00125971722362838
1
0
Number

INPUTBOX
323
42
406
102
beta-artificial
0.0
1
0
Number

INPUTBOX
413
42
488
102
se-artificial
0.0
1
0
Number

INPUTBOX
321
108
413
168
beta-agricultural
1.30707643302806
1
0
Number

INPUTBOX
419
109
502
169
se-agricultural
0.231910053591412
1
0
Number

INPUTBOX
317
231
415
291
beta-scrub
0.609738380725556
1
0
Number

INPUTBOX
429
231
520
291
se-scrub
0.224727638588186
1
0
Number

INPUTBOX
329
304
420
364
beta-bare
1.55328679940249
1
0
Number

INPUTBOX
436
307
527
367
se-bare
0.252529144111392
1
0
Number

INPUTBOX
318
370
399
430
beta-wetlands
-1.0E27
1
0
Number

INPUTBOX
406
369
472
429
se-wetlands
0.0
1
0
Number

INPUTBOX
553
41
693
101
beta-artificial:turning-angle
0.0
1
0
Number

INPUTBOX
699
41
854
101
se-artificial:turning-angle
0.0
1
0
Number

INPUTBOX
551
105
706
165
beta-agricultural:turning-angle
-0.419708823497002
1
0
Number

INPUTBOX
710
105
865
165
se-agricultural:turning-angle
0.108353655332371
1
0
Number

INPUTBOX
319
170
414
230
beta-forest
-0.00491848470064734
1
0
Number

INPUTBOX
420
170
502
230
se-forest
0.204758649001091
1
0
Number

INPUTBOX
549
169
704
229
beta-forest:turning-angle
-0.0262182446074219
1
0
Number

INPUTBOX
710
167
865
227
se-forest:turning-angle
0.102359124697231
1
0
Number

INPUTBOX
553
237
708
297
beta-scrub:turning-angle
0.0327472811652309
1
0
Number

INPUTBOX
719
237
874
297
se-scrub:turning-angle
0.102978986301144
1
0
Number

INPUTBOX
556
314
711
374
beta-bare:turning-angle
0.536239697394549
1
0
Number

INPUTBOX
727
313
882
373
se-bare:turning-angle
0.104711821024613
1
0
Number

INPUTBOX
562
386
717
446
beta-wetlands:turning-angle
-1.0E27
1
0
Number

INPUTBOX
737
389
892
449
se-wetlands:turning-angle
0.0
1
0
Number

INPUTBOX
554
802
709
862
beta-wetlands:step-length
-1.0E27
1
0
Number

INPUTBOX
721
804
876
864
se-wetlands:step-length
0.0
1
0
Number

INPUTBOX
560
480
715
540
beta-artificial:step-length
0.0
1
0
Number

INPUTBOX
723
481
878
541
se-artificial:step-length
0.0
1
0
Number

INPUTBOX
558
546
713
606
beta-agricultural:step-length
0.568945390616945
1
0
Number

INPUTBOX
724
545
879
605
se-agricultural:step-length
0.112870405981353
1
0
Number

INPUTBOX
557
608
712
668
beta-forest:step-length
0.538532805592645
1
0
Number

INPUTBOX
724
609
879
669
se-forest:step-length
0.106778991169404
1
0
Number

INPUTBOX
556
673
711
733
beta-scrub:step-length
0.42893733037284
1
0
Number

INPUTBOX
723
676
878
736
se-scrub:step-length
0.10753258211162
1
0
Number

INPUTBOX
554
738
709
798
beta-bare:step-length
0.50718636136521
1
0
Number

INPUTBOX
722
740
877
800
se-bare:step-length
0.109727569566467
1
0
Number

INPUTBOX
301
467
405
527
beta-slope:summer
-0.0125029344149241
1
0
Number

INPUTBOX
299
530
398
590
beta-slope:winter
0.0
1
0
Number

INPUTBOX
410
467
507
527
se-slope:summer
0.00221782055170543
1
0
Number

INPUTBOX
409
530
506
590
se-slope:winter
0.0
1
0
Number

INPUTBOX
184
869
345
929
beta-distance-to-road:summer
0.0877498936684734
1
0
Number

INPUTBOX
357
870
510
930
se-distance-to-road:summer
0.0311010390550127
1
0
Number

INPUTBOX
183
932
343
992
beta-distance-to-road:winter
0.0
1
0
Number

INPUTBOX
349
933
508
993
se-distance-to-road:winter
0.0
1
0
Number

INPUTBOX
948
580
1140
640
beta-artificial:step-length:winter:male
-0.110619540831889
1
0
Number

INPUTBOX
1143
580
1327
640
se-artificial:step-length:winter:male
0.157058170717006
1
0
Number

INPUTBOX
947
643
1135
703
beta-agricultural:step-length:winter:male
0.0493934233556851
1
0
Number

INPUTBOX
1144
642
1329
702
se-agricultural:step-length:winter:male
0.0832456574391269
1
0
Number

INPUTBOX
948
705
1134
765
beta-forest:step-length:winter:male
0.0192610407639364
1
0
Number

INPUTBOX
1145
704
1330
764
se-forest:step-length:winter:male
0.0372591325695567
1
0
Number

INPUTBOX
948
769
1135
829
beta-scrub:step-length:winter:male
0.0271160497875645
1
0
Number

INPUTBOX
1146
767
1331
827
se-scrub:step-length:winter:male
0.0334920734007395
1
0
Number

INPUTBOX
949
834
1137
894
beta-bare:step-length:winter:male
-0.0490732603869804
1
0
Number

INPUTBOX
1146
830
1333
890
se-bare:step-length:winter:male
0.0406090448357709
1
0
Number

INPUTBOX
950
899
1138
959
beta-wetlands:step-length:winter:male
-1.0E27
1
0
Number

INPUTBOX
1147
897
1336
957
se-wetlands:step-length:winter:male
0.0
1
0
Number

INPUTBOX
1358
577
1556
637
beta-artificial:step-length:summer:male
0.233204332453198
1
0
Number

INPUTBOX
1564
577
1759
637
se-artificial:step-length:summer:male
0.333271935726846
1
0
Number

INPUTBOX
1358
641
1555
701
beta-agricultural:step-length:summer:male
0.258758587040516
1
0
Number

INPUTBOX
1564
641
1763
701
se-agricultural:step-length:summer:male
0.0636615555644124
1
0
Number

INPUTBOX
1357
705
1556
765
beta-forest:step-length:summer:male
0.122465917359963
1
0
Number

INPUTBOX
1563
704
1762
764
se-forest:step-length:summer:male
0.0353364689035707
1
0
Number

INPUTBOX
1356
768
1556
828
beta-scrub:step-length:summer:male
0.117495298879353
1
0
Number

INPUTBOX
1562
768
1762
828
se-scrub:step-length:summer:male
0.0305614791374753
1
0
Number

INPUTBOX
1355
829
1556
889
beta-bare:step-length:summer:male
-0.034699764413956
1
0
Number

INPUTBOX
1562
829
1762
889
se-bare:step-length:summer:male
0.04190524974611
1
0
Number

INPUTBOX
1356
892
1556
952
beta-wetlands:step-length:summer:male
-1.0E27
1
0
Number

INPUTBOX
1564
891
1762
951
se-wetlands:step-length:summer:male
0.0
1
0
Number

INPUTBOX
947
1005
1137
1065
beta-artificial:step-length:winter:female
0.253569683848898
1
0
Number

INPUTBOX
1151
1006
1340
1066
se-artificial:step-length:winter:female
0.118596633849117
1
0
Number

INPUTBOX
946
1070
1139
1130
beta-agricultural:step-length:winter:female
-0.00251210564434179
1
0
Number

INPUTBOX
1152
1069
1342
1129
se-agricultural:step-length:winter:female
0.0493340599672136
1
0
Number

INPUTBOX
946
1133
1138
1193
beta-forest:step-length:winter:female
0.0140116992653785
1
0
Number

INPUTBOX
1152
1133
1344
1193
se-forest:step-length:winter:female
0.0182589798551276
1
0
Number

INPUTBOX
945
1197
1138
1257
beta-scrub:step-length:winter:female
0.0274316880128998
1
0
Number

INPUTBOX
1151
1199
1345
1259
se-scrub:step-length:winter:female
0.0245729205316433
1
0
Number

INPUTBOX
945
1260
1136
1320
beta-bare:step-length:winter:female
-0.0871366331653598
1
0
Number

INPUTBOX
1152
1261
1343
1321
se-bare:step-length:winter:female
0.0372901624933728
1
0
Number

INPUTBOX
943
1323
1138
1383
beta-wetlands:step-length:winter:female
-1.0E27
1
0
Number

INPUTBOX
1152
1323
1344
1383
se-wetlands:step-length:winter:female
0.0372901624933728
1
0
Number

INPUTBOX
1354
1007
1555
1067
beta-artificial:step-length:summer:female
0.0
1
0
Number

INPUTBOX
1563
1006
1760
1066
se-artificial:step-length:summer:female
0.0
1
0
Number

INPUTBOX
1356
1072
1555
1132
beta-agricultural:step-length:summer:female
0.0
1
0
Number

INPUTBOX
1562
1071
1759
1131
se-agricultural:step-length:summer:female
0.0
1
0
Number

INPUTBOX
1357
1136
1555
1196
beta-forest:step-length:summer:female
0.0
1
0
Number

INPUTBOX
1562
1134
1759
1194
se-forest:step-length:summer:female
0.0
1
0
Number

INPUTBOX
1359
1198
1554
1258
beta-scrub:step-length:summer:female
0.0
1
0
Number

INPUTBOX
1564
1197
1759
1257
se-scrub:step-length:summer:female
0.0
1
0
Number

INPUTBOX
1361
1262
1554
1322
beta-bare:step-length:summer:female
0.0
1
0
Number

INPUTBOX
1564
1260
1759
1320
se-bare:step-length:summer:female
0.0
1
0
Number

INPUTBOX
1361
1324
1555
1384
beta-wetlands:step-length:summer:female
-1.0E27
1
0
Number

INPUTBOX
1564
1325
1760
1385
se-wetlands:step-length:summer:female
0.0
1
0
Number

INPUTBOX
553
900
708
960
beta-artificial:distance-to-road
0.0
1
0
Number

INPUTBOX
718
900
873
960
se-artificial:distance-to-road
0.0
1
0
Number

INPUTBOX
552
967
707
1027
beta-agricultural:distance-to-road
-0.18977662926457
1
0
Number

INPUTBOX
722
965
877
1025
se-agricultural:distance-to-road
0.0393866065041926
1
0
Number

INPUTBOX
551
1029
706
1089
beta-forest:distance-to-road
0.0267846256015655
1
0
Number

INPUTBOX
722
1029
877
1089
se-forest:distance-to-road
0.0355512366508593
1
0
Number

INPUTBOX
551
1094
706
1154
beta-scrub:distance-to-road
-0.04120581757881
1
0
Number

INPUTBOX
721
1093
876
1153
se-scrub:distance-to-road
0.0375446583250768
1
0
Number

INPUTBOX
552
1158
707
1218
beta-bare:distance-to-road
-0.191206900814103
1
0
Number

INPUTBOX
720
1156
875
1216
se-bare:distance-to-road
0.0402692245187032
1
0
Number

INPUTBOX
553
1221
708
1281
beta-wetlands:distance-to-road
-1.0E27
1
0
Number

INPUTBOX
721
1218
876
1278
se-wetlands:distance-to-road
0.0
1
0
Number

BUTTON
167
44
230
77
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

MONITOR
239
45
314
90
NIL
count deer
17
1
11

BUTTON
24
116
89
149
NIL
profile
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
103
103
217
163
profile-tick-number
600.0
1
0
Number

TEXTBOX
197
296
326
369
'Wear Fast, Die Young: More Worn Teeth and Shorter Lives in Iberian Compared to Scottish Red Deer'
10
0.0
1

MONITOR
886
35
1128
80
NIL
dt
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
NetLogo 6.3.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="single tester sim" repetitions="1" runMetricsEveryStep="false">
    <setup>clear-all
random-seed behaviorspace-run-number
setup</setup>
    <go>go</go>
    <timeLimit steps="20000"/>
    <exitCondition>hpc-stop = "yes"</exitCondition>
    <enumeratedValueSet variable="se-agricultural:step-length:winter:female">
      <value value="0.0493340599672136"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-bare:step-length:summer:male">
      <value value="0.04190524974611"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-slope:turning-angle">
      <value value="0.00904324706412455"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-wetlands:turning-angle">
      <value value="-1.0E27"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-wetlands:step-length:summer:male">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-forest:step-length:summer:male">
      <value value="0.0353364689035707"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-scrub:turning-angle">
      <value value="0.102978986301144"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-artificial:step-length:summer:female">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-bare:step-length:summer:male">
      <value value="-0.034699764413956"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-bare:step-length:winter:female">
      <value value="-0.0871366331653598"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-forest:step-length:summer:female">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-forest:distance-to-road">
      <value value="0.0355512366508593"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-slope:summer">
      <value value="-0.0125029344149241"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-forest:step-length">
      <value value="0.538532805592645"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-forest:distance-to-road">
      <value value="0.0267846256015655"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-slope:winter">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-distance-from-release">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-distance-to-road:turning-angle">
      <value value="0.148379056270227"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-artificial">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-forest:step-length:winter:male">
      <value value="0.0192610407639364"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-wetlands:step-length">
      <value value="-1.0E27"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-agricultural:step-length:summer:female">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-wetlands:step-length:winter:female">
      <value value="-1.0E27"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pen-down?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-agricultural:step-length:winter:male">
      <value value="0.0493934233556851"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-artificial:distance-to-road">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-wetlands">
      <value value="-1.0E27"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-agricultural:step-length:summer:female">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-distance-to-road:summer">
      <value value="0.0311010390550127"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-wetlands:step-length:winter:male">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-wetlands:step-length:summer:female">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="annual-birth-prob">
      <value value="0.65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-distance-from-release">
      <value value="-0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-forest:turning-angle">
      <value value="-0.0262182446074219"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-artificial:turning-angle">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-forest:step-length:winter:female">
      <value value="0.0182589798551276"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-wetlands:step-length">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-wetlands">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-wetlands:step-length:winter:male">
      <value value="-1.0E27"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-bare:step-length:summer:female">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-distance-to-road:winter">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-bare:turning-angle">
      <value value="0.536239697394549"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-agricultural">
      <value value="1.30707643302806"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-artificial:step-length:winter:female">
      <value value="0.118596633849117"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-agricultural:step-length">
      <value value="0.568945390616945"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-bare:step-length">
      <value value="0.109727569566467"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-slope:step-length">
      <value value="8.09133311833045E-4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-forest:step-length:winter:female">
      <value value="0.0140116992653785"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-agricultural:step-length:winter:male">
      <value value="0.0832456574391269"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-agricultural:turning-angle">
      <value value="-0.419708823497002"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-scrub:turning-angle">
      <value value="0.0327472811652309"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-step-length">
      <value value="0.107406231285947"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-turning-angle">
      <value value="-2.78783818828574"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-agricultural:step-length:winter:female">
      <value value="-0.00251210564434179"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-distance-to-road:winter">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-artificial:turning-angle">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-agricultural:step-length:summer:male">
      <value value="0.258758587040516"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-wetlands:turning-angle">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-forest:step-length">
      <value value="0.106778991169404"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-distance-to-road">
      <value value="0.0368058860666508"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-scrub:step-length:summer:male">
      <value value="0.0305614791374753"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-scrub">
      <value value="0.224727638588186"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-wetlands:distance-to-road">
      <value value="-1.0E27"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-bare:distance-to-road">
      <value value="0.0402692245187032"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-scrub:distance-to-road">
      <value value="-0.04120581757881"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-scrub">
      <value value="0.609738380725556"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-wetlands:step-length:winter:female">
      <value value="0.0372901624933728"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-artificial:step-length:winter:male">
      <value value="0.157058170717006"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-distance-to-road">
      <value value="0.0135678807885984"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-agricultural:turning-angle">
      <value value="0.108353655332371"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-artificial">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-artificial:step-length:summer:male">
      <value value="0.233204332453198"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-scrub:step-length:summer:female">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-slope">
      <value value="0.00183827938722221"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-bare:step-length:winter:female">
      <value value="0.0372901624933728"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-wetlands:step-length:summer:male">
      <value value="-1.0E27"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-forest">
      <value value="0.204758649001091"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-slope">
      <value value="0.025518851504783"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-artificial:step-length:winter:female">
      <value value="0.253569683848898"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-agricultural:step-length">
      <value value="0.112870405981353"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-scrub:step-length:summer:male">
      <value value="0.117495298879353"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-scrub:step-length">
      <value value="0.42893733037284"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-bare:step-length:winter:male">
      <value value="0.0406090448357709"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-bare">
      <value value="1.55328679940249"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-distance-to-road:turning-angle">
      <value value="0.00655605509221779"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-scrub:step-length:winter:male">
      <value value="0.0334920734007395"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-forest:step-length:winter:male">
      <value value="0.0372591325695567"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-agricultural:step-length:summer:male">
      <value value="0.0636615555644124"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-bare:step-length:winter:male">
      <value value="-0.0490732603869804"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-distance-to-road:summer">
      <value value="0.0877498936684734"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-artificial:step-length">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-bare:turning-angle">
      <value value="0.104711821024613"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-slope:turning-angle">
      <value value="0.00125971722362838"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-agricultural">
      <value value="0.231910053591412"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-bare:step-length:summer:female">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-artificial:step-length:winter:male">
      <value value="-0.110619540831889"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-scrub:step-length:winter:female">
      <value value="0.0245729205316433"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-bare:distance-to-road">
      <value value="-0.191206900814103"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-artificial:distance-to-road">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-forest">
      <value value="-0.00491848470064734"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-slope:winter">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-step-length">
      <value value="-0.277981115906896"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-agricultural:distance-to-road">
      <value value="0.0393866065041926"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-artificial:step-length:summer:female">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-scrub:step-length:winter:male">
      <value value="0.0271160497875645"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="profile-tick-number">
      <value value="600"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-lifespan-years">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-wetlands:step-length:summer:female">
      <value value="-1.0E27"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-artificial:step-length">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-turning-angle">
      <value value="0.10743227235049"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-step-distance">
      <value value="26"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-artificial:step-length:summer:male">
      <value value="0.333271935726846"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-forest:turning-angle">
      <value value="0.102359124697231"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-scrub:step-length:winter:female">
      <value value="0.0274316880128998"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-bare:step-length">
      <value value="0.50718636136521"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-scrub:distance-to-road">
      <value value="0.0375446583250768"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="annual-survival-prob">
      <value value="0.97"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-wetlands:distance-to-road">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-scrub:step-length">
      <value value="0.10753258211162"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-bare">
      <value value="0.252529144111392"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-forest:step-length:summer:female">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-forest:step-length:summer:male">
      <value value="0.122465917359963"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-scrub:step-length:summer:female">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-agricultural:distance-to-road">
      <value value="-0.18977662926457"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="se-slope:summer">
      <value value="0.00221782055170543"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-slope:step-length">
      <value value="0.00965050948976871"/>
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
