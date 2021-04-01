String::capitalizeFirstLetter = ->
  this.charAt(0).toUpperCase() + this.slice(1)
String::camelToSpace = ->
  str = this.replace /([A-Z])/g, (g) -> " " + g[0]
  return str.charAt(0).toUpperCase() + str.slice(1);
Number::clamp = (min, max) -> Math.min(Math.max(this, min), max)

export log = () -> console.log.apply(this, arguments)

export rn = (start=0,end=1) ->
  start + Math.random() * (end - start)

export ri = (start=0,end=1) ->
  Math.floor(start + Math.random() * (end - start + 1))

export rv = (value, variance = 0.2) ->
  # multiplies the value by a random variance
  varianceFactor = 1 + ri(variance * 100 * 2) * 0.01 - variance
  return value * varianceFactor

export sri = do () -> # seeded
  SEEDLIMIT = 1000000000
  sriTracker = 353456907
  seed = 1
  return (start=0,end=1) ->
    sriTracker = (sriTracker * 510253 + seed) % SEEDLIMIT
    Math.floor( start + sriTracker/SEEDLIMIT * (end - start + 1) )

export raf = do () ->
  return  window.requestAnimationFrame       ||
          window.webkitRequestAnimationFrame ||
          window.mozRequestAnimationFrame    ||
          (cb) -> window.setTimeout(cb, 1000 / 60)

export mobileCheck = ->
  return /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent)
  # return window.innerWidth <= 800 && window.innerHeight <= 600

export q = (sel) -> document.querySelector(sel)

export Color = class Color
  constructor: (r, g, b, a) ->
    if r instanceof Color
      return r
    else if typeof r == 'string'
      cleanedInput = r.replace(/\s/g, '')
      result = null
      # Parse a 3-digit hex code
      if result = /^#?([a-f\d])([a-f\d])([a-f\d])$/i.exec(cleanedInput)
        @r = parseInt(result[1] + result[1], 16)
        @g = parseInt(result[2] + result[2], 16)
        @b = parseInt(result[3] + result[3], 16)
      else if result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(cleanedInput)
        # Parse a 6-digit hex code
        @r = parseInt(result[1], 16)
        @g = parseInt(result[2], 16)
        @b = parseInt(result[3], 16)
      else if result = /^rgba\(([\d]+),([\d]+),([\d]+),([\d]+|[\d]*.[\d]+)\)/.exec(cleanedInput)
        # Parse rgba()
        @r = +result[1]
        @g = +result[2]
        @b = +result[3]
        @a = +result[4]
      else if result = /^rgb\(([\d]+),([\d]+),([\d]+)\)/.exec(cleanedInput)
        # Parse rgb()
        @r = +result[1]
        @g = +result[2]
        @b = +result[3]
      else
        throw new Error('Invalid color constructor from ' + r)
    else if typeof r == 'object' and typeof r.r == 'number'
      @r = (~~r.r).clamp(0, 255)
      @g = (~~r.g).clamp(0, 255)
      @b = (~~r.b).clamp(0, 255)
      @a = r.a?.clamp?(0, 1)
    else if typeof r == 'number'
      @r = (~~r).clamp(0, 255)
      @g = (~~g).clamp(0, 255)
      @b = (~~b).clamp(0, 255)
      @a = a?.clamp?(0, 1)
    else
      throw new Error('Invalid color constructor from ' + r)
    if typeof @a == 'undefined' or isNaN(@a)
      @a = 1
  toHex: ->
    '#' + ((1 << 24) + (@r << 16) + (@g << 8) + @b).toString(16).slice(1)
  toRgba: (a) ->
    return "rgba(#{@r},#{@g},#{@b},#{a ? @a})"
  mix: (colorRaw, weight = 0.5, mixAlpha = false) ->
    target = new Color(colorRaw)
    x = weight.clamp(0, 1)
    return new Color(
      this.r * (1 - x) + target.r * x,
      this.g * (1 - x) + target.g * x,
      this.b * (1 - x) + target.b * x,
      mixAlpha ? this.a * (1 - x) + target.a * x : this.a,
    )

  # construct a linear gradient though HSLuv space
  toGradientCSSProperty: (toColor, degrees=10, startPercentage=20, endPercentage=80) ->
    if !hsluv
      return ""
    # Try: new Color('#ff0').toGradientCSSProperty('#08f')
    if !(toColor instanceof Color)
      toColor = new Color(toColor)
    startHsl = hsluv.hexToHsluv(@toHex())
    endHsl = hsluv.hexToHsluv(toColor.toHex())
    if endHsl[0] - startHsl[0] > 180
      # make sure hue interpolation wraps around the 360 breakpoint!
      # e.g. end is 350 and start is 10. end is now -10.
      endHsl[0] = endHsl[0] - 360
    ret = "linear-gradient(120deg"
    for i in [0..degrees]
      interH = i / degrees * (endHsl[0] - startHsl[0]) + startHsl[0]
      interS = i / degrees * (endHsl[1] - startHsl[1]) + startHsl[1]
      interL = i / degrees * (endHsl[2] - startHsl[2]) + startHsl[2]
      interHMod360 = (interH + 360) % 360
      interHex = hsluv.hsluvToHex([interHMod360, interS, interL])
      degreePercentage = ((i / degrees * (endPercentage-startPercentage) + startPercentage)).toFixed(2) + '%'
      ret += ", " + interHex + ' ' + degreePercentage
    ret += ")"
    return ret

# window.timerStart ||= new Date().getTime()
# window.timerTemp ||= timerStart
# window.timerCheck ||= (label) ->
#   newTime = new Date().getTime()
#   diff = newTime - window.timerTemp
#   msg = (diff + "ms (total " + (newTime - timerStart) + "ms) - " + label)
#   window.timerTemp = newTime
#   window.growl?(msg); console.log?('[TIMER CHECK] ' + msg)
# window.timerSubTemp = null
# window.timerSubStart = ->
#   window.timerSubTemp = new Date().getTime()
# window.timerSubEnd = (label) ->
#   newTime = new Date().getTime()
#   diff = newTime - window.timerSubTemp
#   msg = ("#{label} took " + diff + "ms")
#   window.growl?(msg); window.log?(msg)

# window.getDevicePixelRatio = () ->
#   ratio = 1
#   # To account for zoom, change to use deviceXDPI instead of systemXDPI
#   if (window.screen.systemXDPI != undefined && window.screen.logicalXDPI != undefined && window.screen.systemXDPI > window.screen.logicalXDPI)
#     # Only allow for values > 1
#     ratio = window.screen.systemXDPI / window.screen.logicalXDPI
#   else if window.devicePixelRatio != undefined
#     ratio = window.devicePixelRatio
#   return ratio
# getDevicePixelRatio()


# window.growl = do ->
#   lifetime = GROWLLIFETIME; padding = 15;
#   height = 25
#   moveUp = () -> $('.tbfb-growl').each (i) ->
#     return if $(this).data('dying')
#     $(this).stop().animate {top: i*height + padding}, 200
#   setInterval moveUp, 200
#   return (msg) ->
#     if (growls = $('.tbfb-growl')).length
#       top = parseInt(growls.last().css('top')) + height
#     else top = padding
#     g = $("<div>").addClass('tbfb-growl').text(msg).css
#       top: top, right: padding
#     setTimeout () ->
#       g.data('dying',true)
#       g.stop().animate {top: "-=5",opacity: 0}, 100, () -> g.remove(); moveUp()
#     , lifetime
#     $('body').append(g)