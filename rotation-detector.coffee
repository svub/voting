maxRes = -> Math.max screen.width, screen.height
html = null
switchRes = (min, max, attr, cls) ->
  if (isRes = min < maxRes() <= max) isnt Meteor?[attr]
    Meteor?[attr] = isRes
    (html ?= $ document?.body?.parentNode)?.toggleClass cls, isRes

check = ->
  if (isLandscapeMode = window.innerWidth > window.innerHeight) isnt Meteor?.isLandscapeMode
    Meteor?.isLandscapeMode = isLandscapeMode
    $ document.body.parentNode
      .toggleClass 'landscape-mode', isLandscapeMode
      .toggleClass 'portrait-mode', not isLandscapeMode
  switchRes 0, 568, 'isLowRes', 'low-res'
  switchRes 568, 1200, 'isMidRes', 'mid-res'
  switchRes 1200, 1919, 'isHighRes', 'high-res'
  switchRes 1919, Number.POSITIVE_INFINITY, 'isHdRes', 'hd-res'

setInterval check, 1000
Meteor.startup check
$ check
$(window).resize check
