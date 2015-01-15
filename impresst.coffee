#jshint bitwise:true, curly:true, eqeqeq:true, forin:true, latedef:true, newcap:true,
#         noarg:true, noempty:true, undef:true, strict:true, browser:true 

# You are one of those who like to know how things work inside?
# Let me show you the cogs that make impress.js run...
((document, window) ->
  "use strict"
  
  # HELPER FUNCTIONS
  
  # `pfx` is a function that takes a standard CSS property name as a parameter
  # and returns it's prefixed version valid for current browser it runs in.
  # The code is heavily inspired by Modernizr http://www.modernizr.com/
  pfx = (->
    style = document.createElement("dummy").style
    prefixes = "Webkit Moz O ms Khtml".split(" ")
    memory = {}
    (prop) ->
      if typeof memory[prop] is "undefined"
        ucProp = prop.charAt(0).toUpperCase() + prop.substr(1)
        props = (prop + " " + prefixes.join(ucProp + " ") + ucProp).split(" ")
        memory[prop] = null
        for i of props
          if style[props[i]] isnt `undefined`
            memory[prop] = props[i]
            break
      memory[prop]
  )()
  
  # `arrayify` takes an array-like object and turns it into real Array
  # to make all the Array.prototype goodness available.
  arrayify = (a) ->
    [].slice.call a

  # `shuffle` shuffles a bunch of elements, using the Fisher-Yates algorithm
  shuffle = (xs) ->
    len = xs.length
    exchange = (i) ->
      j = Math.floor(Math.random() * (i+1))
      #console.log "Swapping indices #{i} (#{xs[i]}) and #{j} (#{xs[j]})"
      swaptmp = xs[i]
      xs[i] = xs[j]
      xs[j] = swaptmp
    exchange i for i in [0..len-1]   
    xs
  
  # `css` function applies the styles given in `props` object to the element
  # given as `el`. It runs all property names through `pfx` function to make
  # sure proper prefixed version of the property is used.
  css = (el, props) ->
    key = undefined
    pkey = undefined
    for key of props
      if props.hasOwnProperty(key)
        pkey = pfx(key)
        el.style[pkey] = props[key]  if pkey isnt null
    el

  
  # `toNumber` takes a value given as `numeric` parameter and tries to turn
  # it into a number. If it is not possible it returns 0 (or other value
  # given as `fallback`).
  toNumber = (numeric, fallback) ->
    (if isNaN(numeric) then (fallback or 0) else Number(numeric))

  
  # `byId` returns element with given `id` - you probably have guessed that ;)
  byId = (id) ->
    document.getElementById id

  
  # `$` returns first element for given CSS `selector` in the `context` of
  # the given element or whole document.
  $ = (selector, context) ->
    context = context or document
    context.querySelector selector

  
  # `$$` return an array of elements for given CSS `selector` in the `context` of
  # the given element or whole document.
  $$ = (selector, context) ->
    context = context or document
    arrayify context.querySelectorAll(selector)

  
  # `triggerEvent` builds a custom DOM event with given `eventName` and `detail` data
  # and triggers it on element given as `el`.
  triggerEvent = (el, eventName, detail) ->
    event = document.createEvent("CustomEvent")
    event.initCustomEvent eventName, true, true, detail
    el.dispatchEvent event
    return

  
  # `translate` builds a translate transform string for given data.
  translate = (t) ->
    " translate3d(" + t.x + "px," + t.y + "px," + t.z + "px) "

  
  # `rotate` builds a rotate transform string for given data.
  # By default the rotations are in X Y Z order that can be reverted by passing `true`
  # as second parameter.
  rotate = (r, revert) ->
    rX = " rotateX(" + r.x + "deg) "
    rY = " rotateY(" + r.y + "deg) "
    rZ = " rotateZ(" + r.z + "deg) "
    (if revert then rZ + rY + rX else rX + rY + rZ)

  
  # `scale` builds a scale transform string for given data.
  scale = (s) ->
    " scale(" + s + ") "

  
  # `perspective` builds a perspective transform string for given data.
  perspective = (p) ->
    " perspective(" + p + "px) "

  
  # `getElementFromHash` returns an element located by id from hash part of
  # window location.
  getElementFromHash = ->
    
    # get id from url # by removing `#` or `#/` from the beginning,
    # so both "fallback" `#slide-id` and "enhanced" `#/slide-id` will work
    byId window.location.hash.replace(/^#\/?/, "")

  
  # `computeWindowScale` counts the scale factor between window size and size
  # defined for the presentation in the config.
  computeWindowScale = (config) ->
    hScale = window.innerHeight / config.height
    wScale = window.innerWidth / config.width
    myScale = (if hScale > wScale then wScale else hScale)
    myScale = config.maxScale  if config.maxScale and myScale > config.maxScale
    myScale = config.minScale  if config.minScale and myScale < config.minScale
    myScale

  
  # CHECK SUPPORT
  body = document.body
  ua = navigator.userAgent.toLowerCase()
  
  # browser should support CSS 3D transtorms 
  
  # and `classList` and `dataset` APIs
  
  # but some mobile devices need to be blacklisted,
  # because their CSS 3D support or hardware is not
  # good enough to run impress.js properly, sorry...
  impressSupported = (pfx("perspective") isnt null) and (body.classList) and (body.dataset) and (ua.search(/(iphone)|(ipod)|(android)/) is -1)
  unless impressSupported
    
    # we can't be sure that `classList` is supported
    body.className += " impress-not-supported "
  else
    body.classList.remove "impress-not-supported"
    body.classList.add "impress-supported"
  
  # GLOBALS AND DEFAULTS
  
  # This is where the root elements of all impress.js instances will be kept.
  # Yes, this means you can have more than one instance on a page, but I'm not
  # sure if it makes any sense in practice ;)
  roots = {}
  
  # some default config values.
  defaults =
    width: 1024
    height: 768
    maxScale: 1
    minScale: 0
    perspective: 1000
    transitionDuration: 1000

  
  # it's just an empty function ... and a useless comment.
  empty = ->
    false

  
  # IMPRESS.JS API
  
  # And that's where interesting things will start to happen.
  # It's the core `impress` function that returns the impress.js API
  # for a presentation based on the element with given id ('impress'
  # by default).
  impress = window.impress = (rootId) ->
    
    # If impress.js is not supported by the browser return a dummy API
    # it may not be a perfect solution but we return early and avoid
    # running code that may use features not implemented in the browser.
    unless impressSupported
      return (
        init: empty
        goto: empty
        prev: empty
        next: empty
      )
    rootId = rootId or "impress"
    
    # if given root is already initialized just return the API
    return roots["impress-root-" + rootId]  if roots["impress-root-" + rootId]
    
    # data of all presentation steps
    stepsData = {}
    
    # element of currently active step
    activeStep = null
    
    # current state (position, rotation and scale) of the presentation
    currentState = null
    
    # array of step elements
    steps = null
    
    # configuration options
    config = null
    
    # scale factor of the browser window
    windowScale = null
    
    # root presentation elements
    root = byId(rootId)
    canvas = document.createElement("div")
    initialized = false
    
    # STEP EVENTS
    #
    # There are currently two step events triggered by impress.js
    # `impress:stepenter` is triggered when the step is shown on the 
    # screen (the transition from the previous one is finished) and
    # `impress:stepleave` is triggered when the step is left (the
    # transition to next step just starts).
    
    # reference to last entered step
    lastEntered = null
    
    # `onStepEnter` is called whenever the step element is entered
    # but the event is triggered only if the step is different than
    # last entered step.
    onStepEnter = (step) ->
      if lastEntered isnt step
        triggerEvent step, "impress:stepenter"
        lastEntered = step
      return

    
    # `onStepLeave` is called whenever the step element is left
    # but the event is triggered only if the step is the same as
    # last entered step.
    onStepLeave = (step) ->
      if lastEntered is step
        triggerEvent step, "impress:stepleave"
        lastEntered = null
      return

    
    # `initStep` initializes given step element by reading data from its
    # data attributes and setting correct styles.
    initStep = (el, idx) ->
      data = el.dataset
      step =
        translate:
          x: toNumber(data.x)
          y: toNumber(data.y)
          z: toNumber(data.z)

        rotate:
          x: toNumber(data.rotateX)
          y: toNumber(data.rotateY)
          z: toNumber(data.rotateZ or data.rotate)

        scale: toNumber(data.scale, 1)
        el: el

      el.id = "step-" + (idx + 1)  unless el.id
      stepsData["impress-" + el.id] = step
      css el,
        position: "absolute"
        transform: "translate(-50%,-50%)" + translate(step.translate) + rotate(step.rotate) + scale(step.scale)
        transformStyle: "preserve-3d"

      return

    
    # `init` API function that initializes (and runs) the presentation.
    init = (options) ->
      return if initialized

      # First we set up the viewport for mobile devices.
      # For some reason iPad goes nuts when it is not done properly.
      meta = $("meta[name='viewport']") or document.createElement("meta")
      meta.content = "width=device-width, minimum-scale=1, maximum-scale=1, user-scalable=no"
      if meta.parentNode isnt document.head
        meta.name = "viewport"
        document.head.appendChild meta

      # Every slideshow has some beginning.  That beginning should have the 'primary' id.
      # For all other slides, put in a 'back' button.  This makes things easier in
      # fullscreen mode.
      prependBackButton = (elem) ->
         dOuter = document.createElement("div")
         css dOuter,
            position: "fixed"
         dInner = document.createElement "div"
         css dInner,
            position: "relative"
            maxHeight: '0px'
            overflow: 'visible'
         bImg = document.createElement "img"
         bImg.className = 'backbutton'
         bImg.src = 'back.svg'
         bImg.addEventListener('click', ->
            window.history.go(-1)
         )
         # create the necessary nesting...
         dInner.appendChild bImg
         dOuter.appendChild dInner
         elem.insertBefore(dOuter, elem.firstChild)
         # reposition img if scrolled
         elem.addEventListener('scroll', ->
            css bImg,
               'top': (elem.scrollTop-(-5)) + 'px'
         )
         
         #elem.insertAdjacentHTML('afterbegin','<div style="position:fixed"><div style="position:relative;max-height:0px;overflow:visible"><img src="back.svg" class="backbutton" onclick="javascript:window.history.go(-1)" /></div></div>')

      setTooltipText = (elem, html) ->
         tSpan = document.createElement 'span'
         tSpan.className = 'my-tooltip'
         elem.classList.add 'tooltip' unless elem.classList.contains 'tooltip'
         tSpan.innerHTML = html
         elem.appendChild tSpan

      setupReferenceLinks = (elem) ->
         if options?.refs?
            if options.refs[elem.dataset.ref]?
               html = 
                  if elem.dataset.refx?
                     "#{options.refs[elem.dataset.ref]} [#{elem.dataset.refx}]"
                  else
                     options.refs[elem.dataset.ref]
               setTooltipText elem, html
            else
               console.log "Ref #{elem.dataset.ref} doesn't have any linked reference."
         else
            console.log "No reference links exist, but reference #{elem.dataset.ref} exists"

      setupTitle = (elem) ->
         setTooltipText(elem, elem.title)
         elem.removeAttribute('title') # Hm. Does this affect accessibility? I don't know.
      
      # Set up the 'back' button
      prependBackButton e for e in $$('.step:not(#primary)')

      # Set up reference links, if any exist.
      setupReferenceLinks e for e in $$('q[data-ref],blockquote[data-ref],span[data-ref]')

      # For consistency, move 'title's to be tooltips.
      setupTitle e for e in $$('*[title]')
      
      # initialize configuration object
      rootData = root.dataset
      config =
        width: toNumber(rootData.width, defaults.width)
        height: toNumber(rootData.height, defaults.height)
        maxScale: toNumber(rootData.maxScale, defaults.maxScale)
        minScale: toNumber(rootData.minScale, defaults.minScale)
        perspective: toNumber(rootData.perspective, defaults.perspective)
        transitionDuration: toNumber(rootData.transitionDuration, defaults.transitionDuration)

      windowScale = computeWindowScale(config)

      # shuffle the slides into different positions
      shuffled_ids =
         shuffle( arrayify($$('div.step')).map((e) -> e.id) )
      getRandom = (max) -> Math.floor (Math.random() * max)
      maxWH = if config.width > config.height then config.width else config.height
      gridSize = Math.ceil(Math.sqrt(shuffled_ids.length))
      console.log "maxWH=#{maxWH}, gridSize=#{gridSize}"
      shuffled_ids.forEach((item_id, idx) ->
         item = document.getElementById item_id
         item.dataset.x = (idx%gridSize)*maxWH*0.9
         item.dataset.y = Math.floor(idx/gridSize)*maxWH*0.9
         console.log "Placing item #{idx} (#{item.id}) at #{item.dataset.x},#{item.dataset.y}"
         item.dataset.z = if Math.random() < 0.5 then getRandom 500 else -(getRandom 500)
         item.dataset.rotate = (getRandom 4)*90
      )
      
      # wrap steps with "canvas" element
      arrayify(root.childNodes).forEach (el) ->
        canvas.appendChild el
        return

      root.appendChild canvas
      
      # set initial styles
      document.documentElement.style.height = "100%"
      css body,
        height: "100%"
        overflow: "hidden"

      rootStyles =
        position: "absolute"
        transformOrigin: "top left"
        transition: "all 0s ease-in-out"
        transformStyle: "preserve-3d"

      css root, rootStyles
      css root,
        top: "50%"
        left: "50%"
        transform: perspective(config.perspective / windowScale) + scale(windowScale)

      css canvas, rootStyles
      body.classList.remove "impress-disabled"
      body.classList.add "impress-enabled"
      
      # get and init steps
      steps = $$(".step", root)
      steps.forEach initStep
      
      # set a default initial state of the canvas
      currentState =
        translate:
          x: 0
          y: 0
          z: 0

        rotate:
          x: 0
          y: 0
          z: 0

        scale: 1

      initialized = true
      triggerEvent root, "impress:init",
        api: roots["impress-root-" + rootId]

      return

    
    # `getStep` is a helper function that returns a step element defined by parameter.
    # If a number is given, step with index given by the number is returned, if a string
    # is given step element with such id is returned, if DOM element is given it is returned
    # if it is a correct step element.
    getStep = (step) ->
      if typeof step is "number"
        step = (if step < 0 then steps[steps.length + step] else steps[step])
      else step = byId(step)  if typeof step is "string"
      (if (step and step.id and stepsData["impress-" + step.id]) then step else null)

    
    # used to reset timeout for `impress:stepenter` event
    stepEnterTimeout = null
    
    # `goto` API function that moves to step given with `el` parameter (by index, id or element),
    # with a transition `duration` optionally given as second parameter.
    goto = (el, duration) ->
      
      # presentation not initialized or given element is not a step
      return false  if not initialized or not (el = getStep(el))
      
      # Sometimes it's possible to trigger focus on first link with some keyboard action.
      # Browser in such a case tries to scroll the page to make this element visible
      # (even that body overflow is set to hidden) and it breaks our careful positioning.
      #
      # So, as a lousy (and lazy) workaround we will make the page scroll back to the top
      # whenever slide is selected
      #
      # If you are reading this and know any better way to handle it, I'll be glad to hear about it!
      window.scrollTo 0, 0
      step = stepsData["impress-" + el.id]
      if activeStep
        activeStep.classList.remove "active"
        body.classList.remove "impress-on-" + activeStep.id
      el.classList.add "active"
      body.classList.add "impress-on-" + el.id
      
      # compute target state of the canvas based on given step
      target =
        rotate:
          x: -step.rotate.x
          y: -step.rotate.y
          z: -step.rotate.z

        translate:
          x: -step.translate.x
          y: -step.translate.y
          z: -step.translate.z

        scale: 1 / step.scale

      
      # Check if the transition is zooming in or not.
      #
      # This information is used to alter the transition style:
      # when we are zooming in - we start with move and rotate transition
      # and the scaling is delayed, but when we are zooming out we start
      # with scaling down and move and rotation are delayed.
      zoomin = target.scale >= currentState.scale
      duration = toNumber(duration, config.transitionDuration)
      delay = (duration / 2)
      
      # if the same step is re-selected, force computing window scaling,
      # because it is likely to be caused by window resize
      windowScale = computeWindowScale(config)  if el is activeStep
      targetScale = target.scale * windowScale
      
      # trigger leave of currently active element (if it's not the same step again)
      onStepLeave activeStep  if activeStep and activeStep isnt el
      
      # Now we alter transforms of `root` and `canvas` to trigger transitions.
      #
      # And here is why there are two elements: `root` and `canvas` - they are
      # being animated separately:
      # `root` is used for scaling and `canvas` for translate and rotations.
      # Transitions on them are triggered with different delays (to make
      # visually nice and 'natural' looking transitions), so we need to know
      # that both of them are finished.
      css root,
        
        # to keep the perspective look similar for different scales
        # we need to 'scale' the perspective, too
        transform: perspective(config.perspective / targetScale) + scale(targetScale)
        transitionDuration: duration + "ms"
        transitionDelay: ((if zoomin then delay else 0)) + "ms"

      css canvas,
        transform: rotate(target.rotate, true) + translate(target.translate)
        transitionDuration: duration + "ms"
        transitionDelay: ((if zoomin then 0 else delay)) + "ms"

      
      # Here is a tricky part...
      #
      # If there is no change in scale or no change in rotation and translation, it means there was actually
      # no delay - because there was no transition on `root` or `canvas` elements.
      # We want to trigger `impress:stepenter` event in the correct moment, so here we compare the current
      # and target values to check if delay should be taken into account.
      #
      # I know that this `if` statement looks scary, but it's pretty simple when you know what is going on
      # - it's simply comparing all the values.
      delay = 0  if currentState.scale is target.scale or (currentState.rotate.x is target.rotate.x and currentState.rotate.y is target.rotate.y and currentState.rotate.z is target.rotate.z and currentState.translate.x is target.translate.x and currentState.translate.y is target.translate.y and currentState.translate.z is target.translate.z)
      
      # store current state
      currentState = target
      activeStep = el
      
      # And here is where we trigger `impress:stepenter` event.
      # We simply set up a timeout to fire it taking transition duration (and possible delay) into account.
      #
      # I really wanted to make it in more elegant way. The `transitionend` event seemed to be the best way
      # to do it, but the fact that I'm using transitions on two separate elements and that the `transitionend`
      # event is only triggered when there was a transition (change in the values) caused some bugs and 
      # made the code really complicated, cause I had to handle all the conditions separately. And it still
      # needed a `setTimeout` fallback for the situations when there is no transition at all.
      # So I decided that I'd rather make the code simpler than use shiny new `transitionend`.
      #
      # If you want learn something interesting and see how it was done with `transitionend` go back to
      # version 0.5.2 of impress.js: http://github.com/bartaz/impress.js/blob/0.5.2/js/impress.js
      window.clearTimeout stepEnterTimeout
      stepEnterTimeout = window.setTimeout(->
        onStepEnter activeStep
        return
      , duration + delay)
      el

    
    # `prev` API function goes to previous step (in document order)
    prev = ->
      prev = steps.indexOf(activeStep) - 1
      prev = (if prev >= 0 then steps[prev] else steps[steps.length - 1])
      goto prev

    
    # `next` API function goes to next step (in document order)
    next = ->
      next = steps.indexOf(activeStep) + 1
      next = (if next < steps.length then steps[next] else steps[0])
      goto next

    
    # Adding some useful classes to step elements.
    #
    # All the steps that have not been shown yet are given `future` class.
    # When the step is entered the `future` class is removed and the `present`
    # class is given. When the step is left `present` class is replaced with
    # `past` class.
    #
    # So every step element is always in one of three possible states:
    # `future`, `present` and `past`.
    #
    # There classes can be used in CSS to style different types of steps.
    # For example the `present` class can be used to trigger some custom
    # animations when step is shown.
    root.addEventListener "impress:init", (->
      
      # STEP CLASSES
      steps.forEach (step) ->
        step.classList.add "future"
        return

      root.addEventListener "impress:stepenter", ((event) ->
        event.target.classList.remove "past"
        event.target.classList.remove "future"
        event.target.classList.add "present"
        return
      ), false
      root.addEventListener "impress:stepleave", ((event) ->
        event.target.classList.remove "present"
        event.target.classList.add "past"
        return
      ), false
      return
    ), false
    
    # Adding hash change support.
    root.addEventListener "impress:init", (->
      
      # last hash detected
      lastHash = ""
      
      # `#/step-id` is used instead of `#step-id` to prevent default browser
      # scrolling to element in hash.
      #
      # And it has to be set after animation finishes, because in Chrome it
      # makes transtion laggy.
      # BUG: http://code.google.com/p/chromium/issues/detail?id=62820
      root.addEventListener "impress:stepenter", ((event) ->
        window.location.hash = lastHash = "#/" + event.target.id
        return
      ), false
      window.addEventListener "hashchange", (->
        
        # When the step is entered hash in the location is updated
        # (just few lines above from here), so the hash change is 
        # triggered and we would call `goto` again on the same element.
        #
        # To avoid this we store last entered hash and compare.
        goto getElementFromHash()  if window.location.hash isnt lastHash
        return
      ), false
      
      # START 
      # by selecting step defined in url or first step of the presentation
      goto getElementFromHash() or steps[0], 0
      return
    ), false
    body.classList.add "impress-disabled"
    
    # store and return API for given impress.js root element
    roots["impress-root-" + rootId] =
      init: init
      goto: goto
      next: next
      prev: prev

  
  # flag that can be used in JS to check if browser have passed the support test
  impress.supported = impressSupported
  return
) document, window

# NAVIGATION EVENTS

# As you can see this part is separate from the impress.js core code.
# It's because these navigation actions only need what impress.js provides with
# its simple API.
#
# In future I think about moving it to make them optional, move to separate files
# and treat more like a 'plugins'.
((document, window) ->
  "use strict"
  
  # throttling function calls, by Remy Sharp
  # http://remysharp.com/2010/07/21/throttling-function-calls/
  throttle = (fn, delay) ->
    timer = null
    ->
      context = this
      args = arguments
      clearTimeout timer
      timer = setTimeout(->
        fn.apply context, args
        return
      , delay)
      return

  
  # wait for impress.js to be initialized
  document.addEventListener "impress:init", ((event) ->
    
    # Getting API from event data.
    # So you don't event need to know what is the id of the root element
    # or anything. `impress:init` event data gives you everything you 
    # need to control the presentation that was just initialized.
    api = event.detail.api
    
    # KEYBOARD NAVIGATION HANDLERS
    
    # Prevent default keydown action when one of supported key is pressed.
    document.addEventListener "keydown", ((event) ->
      event.preventDefault()  if event.keyCode is 9 or (event.keyCode >= 32 and event.keyCode <= 34) or (event.keyCode >= 37 and event.keyCode <= 40)
      return
    ), false
    
    # Trigger impress action (next or prev) on keyup.
    
    # Far fewer key-events are supported by impresst.js.  I expect people to
    # click on what interests them instead of going slide-by-slide!
    document.addEventListener "keyup", ((event) ->
      if event.keyCode is 9 or (event.keyCode >= 32 and event.keyCode <= 34) or (event.keyCode >= 37 and event.keyCode <= 40)
        switch event.keyCode
          when 37 # left
            api.prev()
          when 39 # right
            api.next()
        event.preventDefault()
      return
    ), false
    
    # delegated handler for clicking on the links to presentation steps
    document.addEventListener "click", ((event) ->
      
      # event delegation with "bubbling"
      # check if event target (or any of its parents is a link)
      target = event.target
      target = target.parentNode  while (target.tagName isnt "A") and (target isnt document.documentElement)
      if target.tagName is "A"
        href = target.getAttribute("href")
        
        # if it's a link to presentation step, target this step
        target = document.getElementById(href.slice(1))  if href and href[0] is "#"
      if api.goto(target)
        event.stopImmediatePropagation()
        event.preventDefault()
      return
    ), false
    
    # delegated handler for clicking on step elements
    document.addEventListener "click", ((event) ->
      target = event.target
      
      # find closest step element that is not active
      target = target.parentNode  while not (target.classList.contains("step") and not target.classList.contains("active")) and (target isnt document.documentElement)
      event.preventDefault()  if api.goto(target)
      return
    ), false
    
    # touch handler to detect taps on the left and right side of the screen
    # based on awesome work of @hakimel: https://github.com/hakimel/reveal.js
    document.addEventListener "touchstart", ((event) ->
      if event.touches.length is 1
        x = event.touches[0].clientX
        width = window.innerWidth * 0.3
        result = null
        if x < width
          result = api.prev()
        else result = api.next()  if x > window.innerWidth - width
        event.preventDefault()  if result
      return
    ), false
    
    # rescale presentation when window is resized
    window.addEventListener "resize", throttle(->
      
      # force going to active step again, to trigger rescaling
      api.goto document.querySelector(".step.active"), 500
      return
    , 250), false
    return
  ), false
  return
) document, window

# THAT'S ALL FOLKS!
#
# Thanks for reading it all.
# Or thanks for scrolling down and reading the last part.
#
# I've learnt a lot when building impress.js and I hope this code and comments
# will help somebody learn at least some part of it.
