import {log, ri, rn, rv, sri, raf, q, Color, mobileCheck} from './helpers.coffee'

testChamber = ->
  if DEBUGMODE
    window.C = Color
    window.ps = window.g.planets
    window.p = ps[0]

VERSION = 0.1

###
TODO:
- better arc cursor design - DONE
  - sub arcs - DONE
  - log scale - DONE
  - arrow and ship - DONE
  - bigger number - DONE
  - opacity number - DONE
- localstorage for completed levels - DONE
- zoom - DONE
- pan - DONE
- low-quality trails - DONE
- levels and selector - DONE
- tooltips on planets - DONE
- moving planets - DONE
- mouseover/mouseout on rotating planets - DONE
- restart button - DONE
- save current level to data - DONE
- storage: versioning - DONE
- music: DONE
- SFX: DONE
- get orbits to work with repulsion - DONE
- refactor mouseup/mousedown to not use easel events - DONE
- chasm level - DONE
- ai that predicts rotation - DONE
- dynamic trails based on FPS - DONE
- upgrade to autolauncher - CANCELED
- win condition accounts for leftover units - DONE

- level select: allow scroll *
- level select: different worlds *
- different color schemes *
- tooltip class *
- when launching multiple units, don't deplete all power at once *
- ui for upgrade buttons *
- win/lose screen *
- allow tap on mobile *
- improve ai on defense *

PLANET ZERO
- a quick game of expansion & conquest
- target feeling: strategic/random map-based conquest, like colonizer game on mobile, or eufloria
- game length: 5 - 30 minutes

FEATURES
- no micromanagement
- artifacts "enlightening statue of reason"
- don't do everything! only focus on a few mechanics
  - slow reveal of mechanics: (mechanic discovery https://www.youtube.com/watch?v=FE7lDFAcb4Y)
    - level 1: launch ships and conquer planets
    - lv2: smaller planets more accurate

    - world 2: fast ships
    - world 3: upgrade to autolauncher
    - world 4: moving planets
    - world 5: curved ships
    - world 6: defense satellite

    - overworld: auto growth, starting planet is persistent

    - special planets
    - moving planets
    - starting planet is

    - prestige system: random modifiers (shark clicker)
      - different map types
      - different enemy units
      - different artefacts available

- no boring lategame after 'already won'. keep the uncertainty/exploration phase long and engaging: https://www.youtube.com/watch?v=PJKTDz1zYzs
  - walls / rocks
  - hidden resources, like oil, uranium
- what happens if player idles? is negative progress possible? the fear is that the attention requirement is too high
  - progress should be reduced, but cannot LOSE - only takes longer to recapture
  - but some aspect or resource should still be idle-able, like science

GAMES AS INSPIRATION
Dice wars
- good replayability

SPACEPLAN
http://jhollands.co.uk/spaceplan/
- incremental with story
- highscore donation list

EUFLORIA
- super simple ui/ux

SHARK CLICKER
- always something to do, something to click on.
- great prestige system
  - endgame changes each time (gate goals)
  - world parameters change each time (tar, frozen, etc)
  - speed gets super fast

###

# #######################################################
# CONSTANTS
# #######################################################

# DEBUG
DEBUGMODE = window.location.toString().indexOf('DEBUG') != -1 || window.location.toString().indexOf('localhost') != -1

# CONSTANTS
firstUpdate = false
pi = Math.PI

MAX_CURSOR_RADIUS = 200
TEAM_COLORS = [
  # planet1, planet2, unit, trail
  "#a6b0c0,#505357,#aaaaaa" # GRAY
  "#FFC926,#FF8000,#ffcc66" # ORANGE
  "#68E6FF,#2B60FF,#68E6FF" # BLUE
  "#75EB08,#2D643C,#85DB5B" # GREEN
  "#FF4878,#990020,#EE2050,#aa2848" # RED
  "xxx,xxx"
]
getTeamColor = (team, i=0) ->
  TEAM_COLORS[team].split(',')[i]

# GAME LOGIC
# MAP1 =
#   planets: [
#     {
#       x: -400
#       y: -100
#       r: 45
#       team: 1
#       power: 20
#     },{
#       x: 200
#       y: 400
#       r: 30
#       team: 2
#       power: 10
#     },{
#       x: -200
#       y: 300
#       r: 100
#       team: 0
#       power: 10
#     },{
#       x: 100
#       y: -100
#       r: 20
#       team: 0
#       power: 2
#     },{
#       x: 20
#       y: -40
#       r: 25
#       team: 0
#       power: 5
#     },{
#       x: 0
#       y: 40
#       r: 25
#       team: 0
#       power: 3
#     }
#   ]

MAPS = [{
  name: "Fire & Forget"
  planets: [
    "1t/50r/15p/-150,-20/Click & drag me!" # team/size/power/x,y
    "2t/50r/ 3p/ 150, 20"
  ]
  aiGrowthMultiplier: 0.9
},{
  name: "Sharpshooter"
  planets: [
    "1t/80r/20p/-150,150/Big planets aren't so accurate" # team/size/power/x,y
    "1t/20r/20p/ 150,150/Little planets are more accurate!"
    "2t/30r/10p/   0,-150"
  ]
  playerGrowthMultiplier: 0.75
  aiLaunchMultiplier: 0.1
},{
  name: "Patience"
  planets: [
    "1t/40r/15p/-200,0/Wait for blue to fire first..."
    "0t/60r/15p /  0,0"
    "2t/40r/15p/200,0"
  ]
  playerGrowthMultiplier: 1.35
  aiGrowthMultiplier: 1.1
},{
  name: "Island Hopping"
},{
  name: "Galaxy"
  galaxyLength: 4
},{
  name: "Orbits"
  planets: [
    "1t/40r/10p/-220,0//0,0/1"
    "2t/40r/10p/ 220,0//0,0/1"
    # "0t/60r/10p/0,80//0,0/-0.5"
  ]
  playerGrowthMultiplier: 1.25
},{
  name: "Transport"
  planets: [
    "1t/40r/10p/-500,0/"
    "0t/50r/5p/-625,70/"
    "0t/22r/5p/-610,-65/"

    "2t/40r/10p/ 510,-50/"
    "2t/25r/5p / 490,50/"
    "0t/20r/5p / 550,100/"
    "0t/20r/5p / 620,-140/"
    "0t/20r/5p / 640,20/"

    "0t/50r/5p/-80,280//0,0/-0.667" # big outer orbit
    "0t/35r/8p/80,-280//0,0/-0.667" # big outer orbit
    "0t/60r/10p/0,25//0,0/-2"
    "0t/22r/8p/0,120//0,0/2"
    "0t/25r/8p/-84,-84//0,0/2"
    "0t/20r/8p/84,-84//0,0/2"
  ]
},{
  name: "Chasm"
  planets: [
    "1t/20r/10p/-480,80//-500,120/2"
    "0t/30r/5p/-560,180//-500,120/1"
    "0t/50r/5p/-500,0//-500,120/1"
    "0t/22r/5p/-520,120//-500,120/2"
    "0t/25r/5p/-500,140//-500,120/2"
    "0t/20r/5p/-350,300//-500,120/-2"

    "2t/40r/5p/ 410,-50//400,-120/1"
    "2t/25r/5p / 340,-50//400,-120/1"
    "0t/20r/5p / 450,-100//400,-120/2"
    "0t/20r/5p / 520,-140//400,-120/1"
    "0t/20r/5p / 360,-140//400,-120/2"
    "0t/25r/5p / 400,-180//400,-120/1.5"
    "0t/20r/5p/  250,-300//400,-120/-2"
  ]
  playerGrowthMultiplier: 1.25
  aiGrowthMultiplier: 1.25
},{
  name: "Big Galaxy"
  galaxyLength: 5
  galaxyTeams: 4
  orbit: true
}


# },{
#   name: "Power Up"
#   planets: [
#     "1t/40r/30p/-50,200/Max power... Time to upgrade!"
#     "3t/70r/50p/ 50,-200"
#   ]
#   aiLaunchMultiplier: 0.1
#   aiGrowthMultiplier: 0.1
# }

]

# containers in bottom-to-top layer order
CONTAINERS = [
  'starsCont'
  'planetFxCont'
  'lassoCont'
  'trailsCont'
  'planetsCont'
  'cursorsCont'
  'unitsCont'
]
class Game
  maps: MAPS
  constructor: () ->
    # setInterval =>
    #   $('.tooltip-cont').css
    #     left: @mousePageX - 10
    #     top: @mousePageY - 10
    # , 100

    @storage = new Storage(@)
    @fps = new FPS()
    @tooltipContent = null

    # Stage setup
    @stage = new createjs.Stage("canvas")
    # @stage.enableMouseOver(30) # Check mouseover 30 times/s
    for cName in CONTAINERS
      c = new createjs.Container()
      @stage.addChild(c)
      @[cName] = c
    @setupZoomControls()
    @setupMousePosition()
    @cursorPointer = false
    @paused = false

    # Reset all saves if there is a version upgrade
    if @storage.data.version != VERSION
      @storage.clear()
      @storage.saveProperty('version', VERSION)

    if c = @storage.data.currentLevel
      @loadMap(c)
    else
      nextIncompleteLevel = 0
      for levelData, level in MAPS
        if !@storage.data.levelsCompleted[level]
          nextIncompleteLevel = level
          break
      @loadMap(nextIncompleteLevel)

    @resizeAndCenterMapDebounced = _.debounce(@resizeAndCenterMap, 100)
    $(window).resize @resizeAndCenterMapDebounced
    @stage.update()
    raf(@update)

  pause: -> @paused = !@paused
  unpause: -> @paused = false
  restart: ->
    if confirm("Restart this level?")
      @loadMap(@level)

  getMapProp: (propName) ->
    return @maps[@level][propName]

  confirmLoadMap: (level) ->
    if level == @level
      @unpause()
    else if g.life < 600
      @loadMap(level)
    else if confirm("Are you sure you want to leave the current level?")
      @loadMap(level)

  loadMap: (level=0) ->
    @deleteAllSprites()
    @endGame = false
    @paused = false
    @life = 0
    @planets = []
    @units = []
    @parts = []
    @boundingBoxMemoized = null
    @setupLassoControls()

    # Repeat last level
    if !MAPS[level] && level > MAPS.length - 1
      level = MAPS.length - 1
    @level = level
    @storage.saveProperty('currentLevel', @level)

    if mapData = MAPS[level]
      name = mapData.name
      if mapData.planets
        for pString in mapData.planets
          p = pString.split('/')
          # team/size/power/x/y
          team = parseInt(p[0])
          radius = parseFloat(p[1])
          power = parseInt(p[2])
          x = parseFloat(p[3]?.split(',')[0])
          y = parseFloat(p[3]?.split(',')[1])
          tooltip = p[4]?.trim()
          orbitX = parseFloat(p[5]?.split(',')[0])
          orbitY = parseFloat(p[5]?.split(',')[1])
          orbitSpeed = parseFloat(p[6])
          @planets.push(new Planet(@, x, y, radius, team, power, {
            orbitX: orbitX
            orbitY: orbitY
            orbitSpeed: orbitSpeed
            tooltip: tooltip
          }))
      else if name == "Island Hopping"
        areaX = 1600 * 0.35
        areaY = 800 * 0.35
        @planets.push(player = new Planet(@, -areaX * 1.05, ri(-areaY,areaY), ri(20,50), 1, 20))
        @planets.push(new Planet(@, areaX * 1.05, ri(areaY*0.75,areaY), ri(20,50), 2, 20))
        @planets.push(new Planet(@, areaX * 1.05, -ri(areaY*0.75,areaY), ri(20,50), 3, 20))
        # @planets.push(new Planet(@, ri(0,100), ri(-100,100), ri(20,50), 4, 20))
        for i in [1..ri(7,9)]
          size = ri(10,25) + ri(10,25)
          size *= rn(0.4, 1.5)
          size = size.clamp(20,100)
          @planets.push(new Planet(@, ri(-areaX,areaX), ri(-areaY,areaY), size, 0, ri(2,10)))
      else if name.indexOf("Galaxy") != -1
        @planets.push(new Planet(@, 0, 0, ri(80,100), 0, 20))
        numTeams = mapData.galaxyTeams || 3
        numPlanets = mapData.galaxyLength
        for i in [1..numPlanets]
          dist = 150 + i*60 + ri(0, 20)
          aOffset = rn(-0.5,0.5)
          size = ri(20,40)
          power = ri(5,10)
          startingPower =  ri(15,25)
          team = 0
          for t in [1..numTeams]
            aCircle = t/numTeams * pi*2 + aOffset + pi/2
            x = dist * Math.cos(aCircle)
            y = dist * Math.sin(aCircle)
            if i == numPlanets # player's starting planet
              team = t
              power = startingPower
              if team != 1
                power = ~~(power *= 1.6) # enemies start with higher power
            options = {}
            if mapData.orbit
              options =
                orbitX: 0
                orbitY: 0
                orbitSpeed: -0.25 * 250 / dist
            @planets.push(new Planet(@, x, y, size, team, power, options))
      else
        alert("Error: Level data not found - " + level)


    # Player hint
    # playerPlanet =  _.find(@planets, (p) -> p.team == 1)
    # if playerPlanet
    #   setTimeout =>
    #     playerPlanet.explode()
    #   , 1000

    # Draw background
    for i in [0..150]
      new StarPart(@)

    @setZoom(1)
    @resizeAndCenterMap(true)

  resizeAndCenterMap: (instant=false) =>
    @stage.canvas.width = window.innerWidth
    @stage.canvas.height = window.innerHeight
    MAX_CURSOR_RADIUS = ((window.innerWidth + window.innerHeight) * 0.2).clamp(150, 300)
    bb = @getBoundingBox()

    widthRatio = bb.w / (window.innerWidth * 0.9)
    heightRatio = bb.h / (window.innerHeight * 0.9)
    if widthRatio > 1 || heightRatio > 1
      properZoom = 1 / Math.max(widthRatio, heightRatio)
      @setZoom(properZoom)

    z = @zoom || 1
    panCenter = @getPanCenter()
    @panX = panCenter.x
    @panY = panCenter.y

    # Example:
    ###
    bounds = w: 100, h: 200, x: 50, y: 100
    ###

  update: () =>
    @fps.update()
    raf(@update)
    return if @paused
    # return if @fps.fps < 40

    @life += 1
    @numComputerPlanets = 0; @numPlayerPlanets = 0
    @numComputerUnits = 0; @numPlayerUnits = 0
    for p in @planets
      p?.update()
      @numComputerPlanets += 1 if p.team > 1
      @numPlayerPlanets += 1 if p.team == 1
    for u in @units
      u?.update()
      @numComputerUnits += 1 if u.team > 1
      @numPlayerUnits += 1 if u.team == 1
    for p in @parts
      p?.update()

    if !@endGame
      if @numComputerPlanets == 0 && @numComputerUnits == 0
        setTimeout @win, 700
        @endGame = true
      else if @numPlayerPlanets == 0 && @numPlayerUnits == 0
        setTimeout @lose, 700
        @endGame = true

    # Pan
    if @keys.arrowup || @keys.w
      @pan(0, -15)
    if @keys.arrowleft || @keys.a
      @pan(-15, 0)
    if @keys.arrowdown || @keys.s
      @pan(0, 15)
    if @keys.arrowright || @keys.d
      @pan(15, 0)

    # Zoom
    s = @stage
    tx = (s.tx || 0) - (@panX || 0)
    ty = (s.ty || 0) - (@panY || 0)
    if tx && tx != s.x
      if @life == 1
        s.x = tx; s.y = ty
      else
        s.x += (tx - s.x) * 0.2
        s.y += (ty - s.y) * 0.2
      @onMouseUpdateRecalculate() # Mouse position can change depending on panning/zooming
    if s.tsx && s.tsx != s.scaleX
      s.scaleX += (s.tsx - s.scaleX) * 0.2
      s.scaleY += (s.tsy - s.scaleY) * 0.2

      # counterScale for starsCont - not quite inverse
      @starsCont.scaleX = Math.pow(1 / s.scaleX, 0.8)
      @starsCont.scaleY = Math.pow(1 / s.scaleY, 0.8)
      @starsCont.x = (s.tx + @panX) * 0.9
      @starsCont.y = (s.ty + @panY) * 0.9
      @onMouseUpdateRecalculate() # Mouse position can change depending on panning/zooming

    # Draw lasso
    s = @lasso
    if @isLassoing && @pressStartX && @pressStartY
      s.visible = true
      s.x = @pressStartX
      s.y = @pressStartY
      s.graphics.clear().setStrokeStyle(0.5).beginStroke("#fff").beginFill("rgba(255,255,255,0.05)")
      s.graphics.rect(0,0,@mouseX - @pressStartX,@mouseY - @pressStartY)
      @setLassoedPlanets()
    else
      s.visible = false
    @stage.update()

  isLowRes: ->
    @zoom < 0.7 || mobileCheck()

  win: () =>
    s.play('victory', 0.75)
    setTimeout =>
      alert('you win')
      @storage.completeLevel(@level)
      @loadMap(@level + 1)
    , 500

  lose: () =>
    s.play('loss', 0.75)
    setTimeout =>
      alert('you lose')
      @loadMap(@level)
    , 500

  deleteAllSprites: () ->
    for cName in CONTAINERS
      @[cName].removeAllChildren()
    @cursorPointer = false
    app.$refs.tooltipCont._tooltip.hide()

  setupZoomControls: () ->
    @zoom ||= 1

    scrollEvents = 'mousewheel wheel DOMMouseScroll'
    $(window).off(scrollEvents).on scrollEvents, (e) =>
      if e.type == 'DOMMouseScroll'
        delta = e.originalEvent.detail * -40
      else if e.type == 'touchmove'
        delta = e.originalEvent.touches[0].clientY - lastTouchY
      else
        delta = e.originalEvent.wheelDelta
      if delta > 0
        @setZoom(@zoom + 0.2)
      else if delta < 0
        @setZoom(@zoom - 0.2)

    @keys = {}

    mouseDownHandler = (event) =>
      if @hoverPlanet
        @hoverPlanet.mouseDown()
      else if !@pressedPlanet
        @startLasso()

    mouseUpHandler = (event) =>
      if @pressedPlanet
        @pressedPlanet.pressUp()
      else
        @endLasso()

    document.addEventListener 'keydown', (event) =>
      keyName = event.key.toLowerCase()
      if keyName == ' ' && !@keys[keyName] # Spacebar as an alternative to mousedown
        mouseDownHandler(event)
      else if DEBUGMODE && keyName == 'l' && !@keys[keyName] # Spacebar as an alternative to mousedown
        if @hoverPlanet
          @hoverPlanet.mouseDown('launcher')
      @keys[keyName] = true

    document.addEventListener 'keyup', (event) =>
      keyName = event.key.toLowerCase()
      if keyName == ' ' # Spacebar as an alternative to mouse pressUp
        mouseUpHandler(event)
      else if keyName == 'l' # Spacebar as an alternative to mouse pressUp
        if @pressedPlanet && @pressedMode == 'launcher'
          @pressedPlanet.pressUp('launcher')
        else
          @endLasso()
      @keys[keyName] = false

    document.addEventListener 'mousedown', mouseDownHandler
    document.addEventListener 'mouseup', mouseUpHandler

    $(window).blur =>
      for k, v of @keys
        @keys[k] = false
      @isLassoing = false # cancel lasso
      if @pressedPlanet # cancel launch
        @pressedPlanet = null

  pan: (dx, dy) ->
    z = @zoom
    @panX ||= 0
    @panY ||= 0
    bb = @getBoundingBox()
    panCenter = @getPanCenter()
    xFreedom = ((bb.w*z - window.innerWidth) / 2 + 100).clamp(100, 10000)
    yFreedom = ((bb.h*z - window.innerHeight) / 2 + 100).clamp(100, 10000)
    @panX = (@panX += dx).clamp(panCenter.x - xFreedom, panCenter.x + xFreedom)
    @panY = (@panY += dy).clamp(panCenter.y - yFreedom, panCenter.y + yFreedom)

  getPanCenter: ->
    z = @zoom
    bb = @getBoundingBox()
    panCenter =
      x: -((window.innerWidth - bb.w*z) / 2 - bb.x*z)
      y: -((window.innerHeight - bb.h*z) / 2 - bb.y*z)
    return panCenter

  setupLassoControls: ->
    s = new createjs.Shape()
    s.graphics.clear().beginFill("rgba(0,0,0,0.01)")
    s.graphics.rect(-2000,-2000,4000,4000)
    @lassoCont.addChild(s)
    @lassoStage = s

    s = new createjs.Shape()
    @lassoCont.addChild(s)
    @lasso = s

  startLasso: =>
    @isLassoing = true
    @pressStartX = @mouseX
    @pressStartY = @mouseY
  endLasso: =>
    @isLassoing = false

  setLassoedPlanets: ->
    # Collect all planets in lasso
    for p in @planets when p.team == 1
      xIn = (@mouseX > p.x > @pressStartX) || (@mouseX < p.x < @pressStartX)
      yIn = (@mouseY > p.y > @pressStartY) || (@mouseY < p.y < @pressStartY)
      p.isSelected = xIn && yIn

  deselectAllPlanets: ->
    for p in @planets
      p.isSelected = false

  setupMousePosition: ->
    document.addEventListener('mousemove', @onMouseUpdate, false)
    document.addEventListener('mouseenter', @onMouseUpdate, false)

  onMouseUpdate: (e) =>
    @mousePageX = e.pageX
    @mousePageY = e.pageY
    @onMouseUpdateRecalculate()

  onMouseUpdateRecalculate: ->
    @mouseX = (@mousePageX - @stage.x) / @zoom
    @mouseY = (@mousePageY - @stage.y) / @zoom

  gamePositionToPagePosition: (x, y) ->
    # transforms game coordinates to page coordinates
    return {
      x: x * @zoom + @stage.x
      y: y * @zoom + @stage.y
    }

  setZoom: (z) ->
    return if @paused
    @zoom = z.clamp(0.4, 1.6)
    @stage.tsx = @stage.tsy = @zoom

  getBoundingBox: () ->
    return @boundingBoxMemoized if @boundingBoxMemoized
    minX = Infinity
    maxX = -Infinity
    minY = Infinity
    maxY = -Infinity
    for p in @planets
      if p.orbitRadius && p.orbitX? && p.orbitY?
        if (c = p.orbitX - p.orbitRadius - p.r) < minX then minX = c
        if (c = p.orbitX + p.orbitRadius + p.r) > maxX then maxX = c
        if (c = p.orbitY - p.orbitRadius - p.r) < minY then minY = c
        if (c = p.orbitY + p.orbitRadius + p.r) > maxY then maxY = c
      else
        if (c = p.x - p.r) < minX then minX = c
        if (c = p.x + p.r) > maxX then maxX = c
        if (c = p.y - p.r) < minY then minY = c
        if (c = p.y + p.r) > maxY then maxY = c
    return @boundingBoxMemoized =
      x: minX
      y: minY
      w: maxX - minX
      h: maxY - minY
      x2: maxX
      y2: maxY

class Planet
  constructor: (@game, @x, @y, @r, @team=0, @power=0, @options={}) ->
    $.extend true, @, @options
    @switchTeam(@team)
    @stage = @game.stage
    @speedX = 0
    @speedY = 0

    # smaller planets are more accurate
    # r=17.5 => angle=0
    # r=117.5 => angle=max angle of 1
    @launchAngleRange = Math.sqrt((@r - 17.5).clamp(0, 100)/100)
    @maxPower = 30
    @drawPower()
    @life = 0

    @launcherAngle = 0

    # Rotation!
    if @orbitX? && @orbitY? && !isNaN(@orbitX) && !isNaN(@orbitY)
      dx = @x - @orbitX
      dy = @y - @orbitY
      @orbitRadius = Math.sqrt(dx*dx + dy*dy)

    # Initial draw
    @drawCursor()
    @cursor.visible = false
    @drawSprite()
    @drawHighlight()

  # addToZone: ->

  getFuturePosition: (time) ->
    if @orbitX? && @orbitY? && @orbitAng
      newAng = @orbitAng + @orbitSpeed * 0.0003 * time * 10.5
      x = @orbitX + Math.cos(newAng) * @orbitRadius
      y = @orbitY + Math.sin(newAng) * @orbitRadius
      return [x, y]
    else
      return [@x, @y]

  switchTeam: (team) ->
    oldTeam = @team
    @team = team
    @drawSprite()

    @growth = 0
    @growthSpeed = 0.333 # % per tick
    # Bigger planets grow faster
    # r=100 => 80% bonus
    # r=60 => 40% bonus
    # r=20 => 0% bonus
    @growthSpeed *= 1 + 0.8 * (@r.clamp(20,100) - 20)/80
    if @team == 1
      @growthSpeed *= (@game.getMapProp('playerGrowthMultiplier') || 1) # Player gets an advantage
    else if @team == 0
      @growthSpeed *= 0.1 # Unsettled planets glow very slowly
    else
      @growthSpeed *= (@game.getMapProp('aiGrowthMultiplier') || 1) # AI gets an advantage

    if @team != 1
      @launcherActive = false

    if @mouseInPlanet
      if @team == 1
        @mouseOver()
      else if oldTeam == 1
        @game.cursorPointer = false

    if @life > 10
      @explode()

  explode: ->
    n = if @game.isLowRes() then 10 else 20
    for i in [1..n]
      new ExploPart @game,
        team: @team
        x: @x + @r * Math.cos(pi * 2 * i / n)
        y: @y + @r * Math.sin(pi * 2 * i / n)
        planet: @
        length: 2

  drawSprite: ->
    s = @sprite || new createjs.Shape()
    teamGradient = [getTeamColor(@team,0), getTeamColor(@team,1)]
    @fillCommand = s.graphics.clear().beginLinearGradientFill(teamGradient, [0, 1], -@r*.7, -@r*.7, @r*.7, @r*.7).command
    s.graphics.drawCircle(0, 0, @r)
    s.x = @x
    s.y = @y
    if !@sprite
      @sprite = s
      @game.planetsCont.addChild(s)

  drawHighlight: ->
    s = @hl || new createjs.Shape()
    s.graphics.clear().setStrokeStyle(8).beginStroke("#fff")
    s.graphics.drawCircle(0, 0, @r - 4)
    s.x = @x
    s.y = @y
    s.alpha = 0.5
    s.visible = false
    if !@hl
      @hl = s
      @game.planetsCont.addChild(s)

  drawPower: ->
    if @canUpgrade()
      color = "#ff3c00"
    else color = "white"

    if @powerText
      @powerText.text = @power
      if @launcherActive then @powerText.text = "✦" # star
      @powerText.color = color
      # Remove wobble
      @powerText.scaleX = @powerText.scaleY = 1
    else
      fontSize = 20 + 35 * ((@r-20) / 50).clamp(0, 1)
      t = new createjs.Text(@power, fontSize + "px circular,sans-serif", color)
      t.x = @x
      t.y = @y
      t.textBaseline = 'middle'
      t.textAlign = 'center'
      @game.planetsCont.addChild(t)
      @powerText = t
      @powerText.rotation = 0.1 # So text doesn't jiggle

  drawLauncher: (ang = @launcherAngle, arrowLength = 40) ->
    cont = @launcher || new createjs.Shape()
    cont.x = @x
    cont.y = @y
    cont.alpha = 0.75
    cont.rotation = ang * 180/pi
    if !@launcher
      @game.cursorsCont.addChild(cont)
      @launcher = cont
    # a = cont.arrow || new createjs.Shape()
    g = cont.graphics
    g.clear()
    g.setStrokeStyle(5, "round", "bevel").beginStroke(getTeamColor(@team))
    g.moveTo(@r, 0)
    g.lineTo(@r + arrowLength, 0)
    g.lineTo(@r + arrowLength - 10, -10)
    g.moveTo(@r + arrowLength, 0)
    g.lineTo(@r + arrowLength - 10, 10)

  drawCursor: (options={}) ->
    defaultCursorOptions =
      cursorRadius: 400
      cursorAngle: 0
      showLinesOnly: false
    options = $.extend true, defaultCursorOptions, options

    cursorRadius = options.cursorRadius.clamp(0, MAX_CURSOR_RADIUS)
    # Container
    cont = @cursor || new createjs.Container()
    cont.x = @x
    cont.y = @y
    # cont.alpha = 0.5
    cont.rotation = options.cursorAngle * 180/pi
    if !@cursor
      @game.cursorsCont.addChild(cont)
      @cursor = cont

    c = cont.cursorField || new createjs.Shape()
    c.alpha = 0.5

    fillColor = "#58277A"
    strokeColor = "#983AC2"
    arrowStrokeColor = 'rgba(255,150,225,1)'
    # Calculate the wide angle that units can spawn from
    # launchAngleRange=0 => planetAngleStart=90deg
    # launchAngleRange=90deg => planetAngleStart=135deg
    planetAngleStart = pi/2 + @launchAngleRange/2
    # start
    startX = @r * Math.cos(-planetAngleStart)
    startY = @r * Math.sin(-planetAngleStart)
    c.graphics.moveTo(startX, startY)

    # DIAGRAM: https://i.imgur.com/vUWBXGl.png
    # corner 1
    c1X = startX + cursorRadius * Math.cos(-planetAngleStart + pi/2)
    c1Y = startY + cursorRadius * Math.sin(-planetAngleStart + pi/2)
    arcAngle = Math.atan2(c1Y, c1X)
    arcRadius = Math.sqrt(@r * @r + cursorRadius * cursorRadius)

    c.graphics.clear()

    # cursorLines on either side
    c.graphics.setStrokeStyle(1)
    c.graphics.beginLinearGradientStroke(["rgba(255,255,255,1)","rgba(255,255,255,0)"], [0.8, 1], 0, 0, 1000, 0)
    c1X = startX + 1200 * Math.cos(-planetAngleStart + pi/2)
    c1Y = startY + 1200 * Math.sin(-planetAngleStart + pi/2)
    c.graphics.moveTo(startX, startY)
    c.graphics.lineTo(c1X, c1Y)
    c.graphics.moveTo(startX, -startY)
    c.graphics.lineTo(c1X, -c1Y)

    if !options.showLinesOnly

      # Main field
      c.graphics.beginFill(fillColor)
      c.graphics.setStrokeStyle(1)
      c.graphics.beginStroke(strokeColor)
      # arc from 2 to 3
      c.graphics.arc(0, 0, arcRadius, arcAngle, -arcAngle, false) # x  y  radius  startAngle  endAngle  anticlockwise
      # line from 3 to 4
      c.graphics.lineTo(startX, -startY)
      # arc from 4 to 1
      c.graphics.arc(0, 0, @r + 1, planetAngleStart, -planetAngleStart, true)
      c.graphics.closePath().endFill()

      # sub arcs
      # start = @r
      # end = MAX_CURSOR_RADIUS
      # 1/4 + 1/5 + 1/6 + 1/7 + 1/8 + 1/9
      for rratio in [12/40, 20/40, 27/40, 33/40, 37/40] when rratio * MAX_CURSOR_RADIUS < cursorRadius
        rr = rratio * MAX_CURSOR_RADIUS
        c1X = startX + rr * Math.cos(-planetAngleStart + pi/2)
        c1Y = startY + rr * Math.sin(-planetAngleStart + pi/2)
        arcAngle = Math.atan2(c1Y, c1X)
        arcRadius = Math.sqrt(@r * @r + rr * rr)
        c.graphics.beginStroke(strokeColor)
        c.graphics.moveTo(c1X, c1Y)
        c.graphics.arc(0, 0, arcRadius, arcAngle, -arcAngle, false) # x  y  radius  startAngle  endAngle  anticlockwise

      # arrow
      c.graphics.setStrokeStyle(5, "round", "bevel").beginStroke(arrowStrokeColor)
      c.graphics.moveTo(cursorRadius * 0.5, 0)
      c.graphics.lineTo(cursorRadius * 0.8, 0)
      c.graphics.lineTo(cursorRadius * 0.8 - 10, -10)
      c.graphics.moveTo(cursorRadius * 0.8, 0)
      c.graphics.lineTo(cursorRadius * 0.8 - 10, 10)
      if !cont.cursorField
        cont.addChild(c)
        cont.cursorField = c

    # arrow number / text label
    t = cont.text || new createjs.Text('', "24px circular", "#ffffff")
    if options.showLinesOnly
      t.text = "AUTO"
      t.x = 125
    else
      t.text = @getLaunchNumber()
      t.x = (cursorRadius - 25).clamp(@r + 25, 99999)
    t.rotation = -cont.rotation
    t.textBaseline = 'middle'
    t.textAlign = 'center'
    if !cont.text
      cont.addChild(t)
      cont.text = t

  getPageDimensions: ->
    dims = @game.gamePositionToPagePosition(@x, @y)
    dims.w = dims.h = @r * 2 * @game.zoom
    return dims

  repositionTooltip: ->
    dims = @getPageDimensions()
    $(app.$refs.tooltipCont).css
      left: dims.x - dims.w/2
      top: dims.y - dims.h/2
      width: dims.w
      height: dims.h

  # getTooltip: ->
  #   if @canUpgrade()
  #     return "Ready for upgrade!"
  #   else return @tooltip

  checkHover: ->
    if @game.hoverPlanet != @
      if @mouseInPlanet
        @mouseOver()
    else if @game.hoverPlanet == @
      if !@mouseInPlanet
        @mouseOut()

  mouseOver: (e) =>
    @game.hoverPlanet = @
    if t = @tooltip
      @game.tooltipContent = t
      app.$refs.tooltipCont._tooltip.show()
      @repositionTooltip()
    if @team == 1
      @game.cursorPointer = true

  mouseOut: (e) =>
    if @game.hoverPlanet == @
      @game.hoverPlanet = null
    if @tooltip
      # @game.tooltipContent = null
      app.$refs.tooltipCont._tooltip.hide()
    if @team == 1 && !@isPressed()
      @game.cursorPointer = false

  isPressed: ->
    return @game.pressedPlanet == @

  mouseDown: (e) =>
    if @team == 1
      if !@isSelected
        @game.deselectAllPlanets()
      @game.pressedPlanet = @

  pressUp: (e) =>
    if @canLaunch() && @game.pressedMode != 'launcher'
      n = @getLaunchNumber()
      # proportion = n / @power
      @spawnUnits(n, @cursorAngle)

      # Spawn from lassoed planets
      if @isSelected
        for p in @game.planets when p != @
          if p.isSelected && p.team == 1
            # n = ~~((proportion * p.power).clamp(0, p.power))
            p.spawnUnits(p.getLaunchNumber(), p.cursorAngle)
      @game.deselectAllPlanets()

    else if @canSetLauncher()
      @launcherAngle = @cursorAngle
      @launcherActive = true
      @drawPower()
      # Set launcher for lassoed planets
      if @isSelected
        for p in @game.planets when p != @
          if p.isSelected && p.team == 1
            p.launcherAngle = p.cursorAngle
            p.launcherActive = true
            p.drawPower()

    if !@mouseInPlanet
      @game.cursorPointer = false

    # Select single planet
    if @isPressed() && @mouseInPlanet
      @isSelected = true

    # Deactivate launcher
    if @mouseInPlanet && @game.pressedMode == 'launcher'
      @launcherActive = false
      @drawPower()

    @game.pressedPlanet = null
    @game.pressedMode = null

  spawnUnit: (ang=0, angRange=@launchAngleRange, cost=1, delay=0) ->
    @game.units.push(u = new Unit(@game, @, ang, angRange, delay))
    @power -= cost
    @drawPower()
    return u

  spawnUnits: (n, ang=0, angRange=@launchAngleRange, cost=1) ->
    if @power < cost * n
      n = ~~(@power / cost)
    if n == 0
      return
    for i in [1..n]
      @spawnUnit(ang, angRange, cost, i * 4)

  getLaunchNumber: ->
    proportion = (@mouseDist - @r) / (MAX_CURSOR_RADIUS - @r)
    proportion = proportion.clamp(0, 1)
    return (~~((@power + 1) * proportion)).clamp(1, @power)

  canLaunch: ->
    @team == 1 && @isPressed() && !@mouseInPlanet && @power

  canSetLauncher: ->
    @team == 1 && @isPressed() && !@mouseInPlanet && @game.pressedMode == 'launcher'

  canLaunchLasso: ->
    # Launch this planet as part of lasso
    @team == 1 && @isSelected && @game.pressedPlanet && !@isPressed() && @game.pressedPlanet.canLaunch() && @power && !@launcherActive

  canUpgrade: ->
    return false
    @team == 1 && @power >= @maxPower && !@launcherActive

  update: ->
    @life += 1
    if @growth < 100
      @growth += @growthSpeed
      # Speed the game up if it's too long!
      if @life > 5000
        @growth += @growthSpeed * @life/10000
      if @life > 2000
        @growthSpeed *= 1.00001 # Growthspeed acceleration

    # Growth
    if @growth >= 100 && @power < @maxPower
      @power += 1
      @drawPower()
      @growth = 0

    # Repulsion
    gotRepulsion = false
    if @life % 5 == 0
      for p in @game.planets when p != @ # Loop over all other planets
        dist = Math.sqrt(Math.pow(p.x-@x,2) + Math.pow(p.y-@y,2))
        threshhold = @r + p.r + 10
        if dist < threshhold
          forceMultiplier = (1 - dist / threshhold)
          pAng = Math.atan2(p.y - @y + rn(-0.01,0.01), p.x - @x + rn(-0.01,0.01))
          repulsionForceX = -Math.cos(pAng) * forceMultiplier
          repulsionForceY = -Math.sin(pAng) * forceMultiplier
          @speedX += repulsionForceX
          @speedY += repulsionForceY
          gotRepulsion = true

    # Orbit movement
    if @orbitX? && @orbitY? && @orbitRadius && @life % 5 == 0
      if gotRepulsion
        dx2 = @x - @orbitX + repulsionForceX
        dy2 = @y - @orbitY + repulsionForceY
        tempRadius = Math.sqrt(dx2*dx2 + dy2*dy2)
        @orbitRadius += (tempRadius - @orbitRadius) * 0.5 # Adjust radius
      dx = @x - @orbitX
      dy = @y - @orbitY
      @orbitAng = Math.atan2(dy, dx)
      newAng = @orbitAng + @orbitSpeed * 0.0003 * 5
      newPosX = @orbitX + Math.cos(newAng) * @orbitRadius
      newPosY = @orbitY + Math.sin(newAng) * @orbitRadius
      @speedX += ((newPosX - @x) * .5).clamp(-1,1)
      @speedY += ((newPosY - @y) * .5).clamp(-1,1)

    # Movement
    @x += @speedX
    @y += @speedY
    for i in ['hl','sprite','cursor','powerText']
      @[i].x = @x
      @[i].y = @y

    # Drag
    @speedX *= 0.95
    @speedY *= 0.95

    # Highlight
    @hl.visible = false
    if @team == 1
      if @isPressed() || @isSelected
        @hl.visible = true
        @hl.alpha = 1
      else if @mouseInPlanet && !@game.lasso.visible
        @hl.visible = true
        @hl.alpha = 0.5

    # Cursor angle, cursor properties
    dy = @game.mouseY - @y
    dx = @game.mouseX - @x
    @cursorAngle = Math.atan2(dy, dx)
    @mouseDist = Math.sqrt(dy*dy + dx*dx)
    @mouseInPlanet = @mouseDist < @r + 2

    @checkHover()

    # Cursor check, draw lines
    @launcher?.visible = false
    @cursor?.visible = false

    # Determine pressedMode
    if @isPressed()
      if !@game.pressedMode && (@canUpgrade() || @launcherActive)
        @game.pressedMode = 'launcher'
      else if @game.pressedMode == 'launcher' && !@canUpgrade() && !@launcherActive
        @game.pressedMode = null

    if @canSetLauncher()
      # Draw launcher cursor
      @drawLauncher(@cursorAngle)
      @drawCursor
        showLinesOnly: true
        cursorAngle: @cursorAngle
      @launcher.visible = true
      @cursor.visible = true
    else if @canLaunch() || @canLaunchLasso()
      # Draw regular cursor
      @drawCursor
        cursorRadius: @mouseDist
        cursorAngle: @cursorAngle
      @cursor.visible = true

    # Spawn from launcher
    if @launcherActive && @launcherAngle
      if !@canSetLauncher() # Don't draw the real launcher if we're setting up a new launcher
        @drawLauncher(@launcherAngle)
      if ri(0, 100 - @power) == 0 && @power > 1
        @spawnUnits(1, @launcherAngle, null, 0)
      @launcher.visible = true

    # AI
    if @team > 1 && ri(0,250) == 0 && @life > 100
      if @power > 4
        targetPlanet = null; minDist = Infinity
        for p in @game.planets
          if p.team != @team
            # find the nearest planet
            dist = Math.sqrt(Math.pow(p.x-@x, 2) + Math.pow(p.y-@y, 2))
            if dist < minDist
              minDist = dist
              targetPlanet = p
        if targetPlanet
          [tx, ty] = targetPlanet.getFuturePosition(minDist * 1) # dist*1 is the unit speed
          if Math.abs(targetPlanet.orbitSpeed) >= 0.4
            distToFuturePos = Math.sqrt(Math.pow(tx-@x, 2) + Math.pow(ty-@y, 2))
            [tx, ty] = targetPlanet.getFuturePosition(distToFuturePos * 1)
            aiInaccuracy = 5
            [tx, ty] = [tx + rn(-1,1)*aiInaccuracy, ty + rn(-1,1)*aiInaccuracy]
            if Math.abs(targetPlanet.orbitSpeed) >= 1.4 # Refine again
              distToFuturePos = Math.sqrt(Math.pow(tx-@x, 2) + Math.pow(ty-@y, 2))
              [tx, ty] = targetPlanet.getFuturePosition(distToFuturePos * 1)
              [tx, ty] = [tx + rn(-1,1)*aiInaccuracy, ty + rn(-1,1)*aiInaccuracy]
          targetAng = Math.atan2(ty - @y, tx - @x)
          minLaunchProportion = 0.5
          maxLaunchProportion = 1
          f = @game.getMapProp('aiLaunchMultiplier')
          if f? # f can be 0
            minLaunchProportion *= f
            maxLaunchProportion *= f
          launchNumber = ~~(@power * rn(minLaunchProportion, maxLaunchProportion))
          @spawnUnits(launchNumber, targetAng)

    # Power animation
    if @powerText && @canUpgrade()
      @powerText.scaleX = @powerText.scaleY = 1 + Math.sin(@life * 0.1) * 0.15 + 0.075
      @powerText.rotation = Math.sin(@life * 0.05) * 5

class Unit
  constructor: (@game, @planet, @mouseAngle, @angleRange, @delay) ->
    @size = 0.35
    @speed = 1 + rn(-0.05,0.05)
    if !@angleRange? then @angleRange = @planet.launchAngleRange

    @team = @planet.team

    @color = getTeamColor(@team,2)
    _trailColor = getTeamColor(@team,3) ? getTeamColor(@team,1)
    @trailColor = new Color('#2D225B').mix(_trailColor, 0.5).toHex()

    @hasTrail = if mobileCheck()
      false
    else if @game.fps.fps > 52
      true
    else if @game.fps.fps > 44
      ri(0,100) > 25
    else if @game.fps.fps > 36
      ri(0,100) > 50
    else if @game.fps.fps > 28
      ri(0,100) > 75
    else
      false

    # Resolve angle
    partial = rn(-0.4, 0.4) + rn(-0.1, 0.1) # weight slightly toward middle, not uniformly distributed!
    @angle = @mouseAngle + partial * @angleRange

    # Calculate planet start angle - where on the surface of the planet the unit will spawn
    planetAngleStart = pi/2 + @angleRange/2
    @positionAngle = @mouseAngle + partial * planetAngleStart * 2 * 0.9

  drawSprite: ->
    s = new createjs.Shape()
    s.graphics.clear().beginFill(@color)
    s.graphics.moveTo(15 * @size, 0)
    s.graphics.lineTo(-15 * @size, 10 * @size)
    s.graphics.lineTo(-10 * @size, 0)
    s.graphics.lineTo(-15 * @size, -10 * @size)
    s.graphics.closePath()

    # Starting point
    s.x = @planet.x + (@planet.r * 0.9 - 5) * Math.cos(@positionAngle)
    s.y = @planet.y + (@planet.r * 0.9 - 5) * Math.sin(@positionAngle)

    # randomRadius = Math.pow(rn(0, Math.sqrt(@planet.r)), 2)
    # randomAngle = rn(0, pi*2)
    # s.x = @planet.x + randomRadius * Math.cos(randomAngle)
    # s.y = @planet.y + randomRadius * Math.sin(randomAngle)

    # s.y = @planet.y + (@planet.r - 5) * Math.sin(@positionAngle)
    s.rotation = @angle * 180 / pi

    # Allow to grow
    s.scaleX = 0.01
    s.scaleY = 0.01
    if !@sprite
      @sprite = s
      @game.unitsCont.addChild(s)

  drawTrail: (len) ->
    t = @trail || new createjs.Shape()
    t.graphics.clear()
    # if !@trailGradient # memoize
    #   @trailColor = new Color(@trailColor)
    #   @trailGradient = [@trailColor.toRgba(0.75), @trailColor.toRgba(0)]
    # if !@game.isLowRes() && false
    #   t.graphics.setStrokeStyle(1).beginLinearGradientStroke(@trailGradient, [0, 1], 0, 0, -w, 0)
    #   # t.graphics.rect(-w, -1, w, 2)
    #   t.graphics.moveTo(0, 0)
    #   t.graphics.lineTo(-w, 0)
    # else
    t.graphics.setStrokeStyle(1).beginStroke( @trailColor )
    t.graphics.moveTo(0, 0)
    t.graphics.lineTo(-len, 0)
    # t.graphics.moveTo(0, 0)
    # t.graphics.lineTo(-w*0.4, 0)
    # t.graphics.beginStroke(bg.mix(c, 0.33).toHex())
    # t.graphics.moveTo(-w*0.4, 0)
    # t.graphics.lineTo(-w*0.6, 0)
    # t.graphics.beginStroke(bg.mix(c, 0.2).toHex())
    # t.graphics.moveTo(-w*0.6, 0)
    # t.graphics.lineTo(-w*0.75, 0)
    # t.graphics.beginStroke(bg.mix(c, 0.1).toHex())
    # t.graphics.moveTo(-w*0.75, 0)
    # t.graphics.lineTo(-w*0.85, 0)
    # t.graphics.beginStroke(bg.mix(c, 0.06).toHex())
    # t.graphics.moveTo(-w*0.85, 0)
    # t.graphics.lineTo(-w*0.95, 0)
    # t.graphics.beginStroke(bg.mix(c, 0.03).toHex())
    # t.graphics.moveTo(-w*0.95, 0)
    # t.graphics.lineTo(-w*1, 0)

    t.rotation = @angle * 180 / pi + 180
    if !@trail
      @trail = t
      @game.trailsCont.addChild(t)
    return t

  update: ->
    @life ||= 0
    if @delay > 0
      @delay -= 1
    if @delay == 0 && !@sprite
      @drawSprite()
    if @delay == 0
      @life += 1

    s = @sprite
    return if !s # Lie dormant

    # Store original coordinates
    @ox ||= s.x
    @oy ||= s.y

    # Movement
    dx = @speed * Math.cos(@angle)
    dy = @speed * Math.sin(@angle)
    if @dead
      dx *= 0.75; dy *= 0.75;
    s.x += dx * s.scaleX
    s.y += dy * s.scaleX

    # Redraw trail
    if @life % 10 == 0 && @hasTrail
      dx = s.x - @ox
      dy = s.y - @oy
      distFromOrigin = Math.sqrt(dx*dx + dy*dy) + 5
      t = @drawTrail(distFromOrigin)
      t.x = @ox
      t.y = @oy

    if @dead
      s.scaleY = s.scaleX *= 0.85
      @trail?.alpha = s.scaleX # fade trail
      # Colliding with a planet
      if s.scaleX < 0.15 && !@unleashedParticles && @targetPlanet
        @unleashParticles(@targetPlanet)
        @unleashedParticles = true
      # Final death
      if s.scaleX <= 0.05
        @collide(@targetPlanet) if @targetPlanet
        @remove()
    else
      if s.scaleX <= 1 && @delay <= 0
        # Spawn
        s.scaleX += (1 - s.scaleX) * 0.075
        s.scaleY = s.scaleX
      if @life % 7 == 0 # Only check occasionally - this reduces lag and adds some randomness to the collision position
        @checkCollisions()
      if @life > 2000 * @speed # Death by age
        @dead = true
      else if @life % 100 == 0 # Death by outside bounds
        dd = 60 # buffer distance
        bb = @game.getBoundingBox()
        if s.x < bb.x - dd || s.x > bb.x + bb.w + dd || s.y < bb.y - dd || s.y > bb.y + bb.h + dd
          @dead = true

  checkCollisions: ->
    s = @sprite
    for p in @game.planets
      if p != @planet
        dist = Math.sqrt(Math.pow(s.x - p.x, 2) + Math.pow(s.y - p.y, 2))
        if dist < p.r
          @dead = true
          return @targetPlanet = p
          break

  unleashParticles: (targetPlanet) ->
    if targetPlanet.team != @team
      n = ri(1,2) + ri(1,2)
      if @game.isLowRes() then n = 1
      for i in [1..n]
        new ExploPart(@game, {team: @team, x: @sprite.x, y: @sprite.y, planet: targetPlanet})

  collide: (targetPlanet) ->
    t = targetPlanet
    if @team == 1
      s.play('blip', 0.14)
    else
      s.play('blip2', 0.08)
    if t.team == @team
      if t.power < t.maxPower
        t.power += 1
    else if t.power <= 0
      t.power = 1
      t.switchTeam(@team)
      if @team == 1
        s.play('pulse', 0.5)
      else
        s.play('pulse2', 0.25)
    else
      t.power -= 1
      t.power = t.power.clamp(0, 999)
      if t.launcherActive
        # Taking any hit will deactivate the launcher
        t.launcherActive = false
        t.growth = 0
      else
        t.growth *= 0.5 # delay growth a bit
    t.drawPower()

  remove: ->
    @sprite.parent.removeChild(@sprite)
    @trail?.parent.removeChild(@trail)
    i = @game.units.indexOf(@)
    @game.units.splice(i, 1)

class FPS
  constructor: (@game) ->
    @filterStrength = 20
    @frameTime = 0
    @lastLoop = new Date
    @fps = 0

    # fpsOut = document.getElementById('fps')
    setInterval =>
      @fps = 1000/@frameTime
      # fpsOut.innerHTML = @fps.toFixed(1) + " fps"
    , 500

  update: ->
    thisFrameTime = (thisLoop = new Date) - @lastLoop
    @frameTime += (thisFrameTime - @frameTime) / @filterStrength
    @lastLoop = thisLoop

class Part
  constructor: (@game, props) ->
    $.extend true, @, props
    @game.parts.push @
    @sprite = @draw()
    @game[@parentContName].addChild(@sprite)
  destroy: ->
    @sprite.parent.removeChild(@sprite)
    i = @game.parts.indexOf(@)
    @game.parts.splice(i, 1)

# class RingPart extends Part
#   parentContName: 'planetFxCont'
#   draw: ->
#     s = @sprite || new createjs.Shape()
#     thickness = 1
#     s.graphics.clear().setStrokeStyle(thickness).beginStroke(getTeamColor(@planet.team))
#     s.graphics.drawCircle(0, 0, @planet.r - thickness).closePath()
#     s.graphics.drawCircle(0, 0, @planet.r - thickness - 5).closePath() if @planet.r - thickness - 5 > 0
#     s.graphics.drawCircle(0, 0, @planet.r - thickness - 10).closePath() if @planet.r - thickness - 10 > 0
#     s.alpha = 0.5
#     s.x = @planet.x
#     s.y = @planet.y
#     return s
#   update: ->
#     s = @sprite
#     s.scaleX += (2 - s.scaleX) * 0.02
#     s.scaleY = s.scaleX
#     s.alpha *= 0.98
#     if s.alpha <= 0.01
#       @destroy()

class ExploPart extends Part
  parentContName: 'unitsCont'
  draw: ->
    length = rn(0.5,2) * rn(0.5,2) * (@length || 1)
    s = @sprite || new createjs.Shape()
    s.graphics.clear().setStrokeStyle(1).beginStroke(getTeamColor(@team))
    s.graphics.moveTo(0,0)
    s.graphics.lineTo(length,0)
    @ang = Math.atan2(@y - @planet.y, @x - @planet.x) + rn(-0.25,0.25)
    @speed = rn(1,2)
    s.rotation = @ang * 180 / pi
    s.x = @x * 0.9 + 0.1 * @planet.x
    s.y = @y * 0.9 + 0.1 * @planet.y
    return s
  update: ->
    s = @sprite
    @life ||= 0; @life += 1
    if @life < 5
      s.scaleX *= (1 + 0.2 * (5 - @life))
      @speed *= 0.99
    else
      s.scaleX *= 0.97
      s.alpha *= 0.98
      s.x += @speed * Math.cos(@ang)
      s.y += @speed * Math.sin(@ang)
      @speed *= 0.96
    if s.scaleX <= 0.04
      @destroy()

class StarPart extends Part
  parentContName: 'starsCont'
  draw: ->
    s = @sprite || new createjs.Shape()
    s.graphics.clear().beginFill("#775CF4")
    s.graphics.moveTo(0,0)
    s.graphics.arc(1, -1, 1, pi/2, pi) # x  y  radius  startAngle  endAngle
    s.graphics.arc(-1, -1, 1, 0, pi/2)
    s.graphics.arc(-1, 1, 1, -pi/2, 0)
    s.graphics.arc(1, 1, 1, pi, -pi/2)
    s.graphics.closePath()
    scale = ri(2,3) + rn(0,1.5) * rn(0,1.5) * rn(0,1.5)
    @z = 1 / scale / scale
    s.scaleX = scale
    s.scaleY = scale
    @x = s.x = ri(-1200, 1200)
    @y = s.y = ri(-600, 600)
    s.alpha = rn(0.25, 1)
    return s
  update: ->
    s = @sprite
    s.x = @x + (@game.mouseX || 0) * -0.08 * @z
    s.y = @y + (@game.mouseY || 0) * -0.08 * @z

class Storage
  localStorageKey: "planetZeroSaveData"
  constructor: (@game) ->
    if @data = @load()
      log "Loaded!"
    else
      @init()
  init: ->
    @data = {
      levelsCompleted: []
      stars: 0
      currentLevel: 0
      soundEnabled: true
    }
    @save(@data)
  save: (data) ->
    localStorage.setItem(@localStorageKey, JSON.stringify(data))
  load: ->
    JSON.parse(localStorage.getItem(@localStorageKey))
  isLevelComplete: (level) ->
    @data.levelsCompleted[level]
  completeLevel: (level) ->
    @data.levelsCompleted[level] = true
    @save(@data)
  saveProperty: (prop, val) ->
    @data[prop] = val
    @save(@data)
  clear: ->
    localStorage.clear()
    @init()

class Sound
  constructor: (@game) ->
    @buffer = []
    @preload()
  preload: (list) ->
    list ||= "bongo,blip,blip2,pulse,pulse2,victory,loss"
    for i in list.split(',')
      @buffer[i] = new Audio("./sfx/" + i + ".wav")
      @buffer[i].volume = 0.01
      @buffer[i].play()
    @music = new Audio("./music1.mp3")
    @music.loop = true
    if @game.storage.data.soundEnabled
      @music.currentTime = 2
      @music.play()
  play: (name, volume=0.25) ->
    return if !@game.storage.data.soundEnabled
    sound = @buffer[name]
    if !sound
      @preload(name)
      sound = @buffer[name]
    sound.currentTime = 0
    sound.volume = volume
    sound.play()

  toggleSound: ->
    enabled = !@game.storage.data.soundEnabled
    @game.storage.saveProperty('soundEnabled', enabled)
    if enabled
      @music.play()
    else
      @music.pause()

window.app = new Vue
  el: '#app'
  data:
    g: {}
window.app.g = window.g = new Game()
window.app.s = window.s = new Sound(g)
testChamber()