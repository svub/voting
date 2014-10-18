configurations =
  general:
    resolution: -> Math.max screen.width, screen.height
    map:
      'low-res':  [0, 568]
      'mid-res':  [568, 1200]
      'high-res': [1200, 1919]
      'hd-res':   [1919]
  horizontal:
    resolution: -> screen.width
    map:
      'x-low-res':  [0, 568]
      'x-mid-res':  [568, 1200]
      'x-high-res': [1200, 1919]
      'x-hd-res':   [1919]
  vertical:
    resolution: -> screen.height
    map:
      'y-low-res':  [0, 568]
      'y-mid-res':  [568, 1200]
      'y-high-res': [1200, 1919]
      'y-hd-res':   [1919]

#object = Meteor = {}
#object = Meteor.responsiveDesignHelper = {}
object = Meteor.responsive = {}

# check device state and adjust css classes and attributes
check = -> if (node = document?.body?.parentNode)? and (node = $ node)?.length > 0
  if (isLandscapeMode = window.innerWidth > window.innerHeight) isnt Meteor?.isLandscapeMode
    Meteor?.isLandscapeMode = isLandscapeMode
    node .toggleClass 'landscape-mode', isLandscapeMode
      .toggleClass 'portrait-mode', not isLandscapeMode
  for own name, config of configurations
    resolution = config.resolution()
    for own cssClass, minMax of config.map
      switchRes node, resolution, minMax[0] ? 0, minMax[1] ? Number.POSITIVE_INFINITY, cssClass

  #switchRes node, res, 0, 568, 'isLowRes', 'low-res'
  #switchRes node, res, 568, 1200, 'isMidRes', 'mid-res'
  #switchRes node, res, 1200, 1919, 'isHighRes', 'high-res'
  #switchRes node, res, 1919, Number.POSITIVE_INFINITY, 'isHdRes', 'hd-res'

# hook up handlers: check every 1s, on Meteor start up, on DOM ready, and on window resize
setInterval check, 1000
Meteor.startup check
$ check
$(window).resize check

# helper methods
toAttributeName = (cssClass) -> 'is'+_s.camelize _s.humanize cssClass
switchRes = (node, res, min, max, cls) ->
  if node? and (isRes = min < res <= max) isnt object?[attr = toAttributeName cls]
    object?[attr] = isRes
    node.toggleClass cls, isRes
