Monocle.Controls.Contents = function (reader) {
  if (Monocle.Controls == this) {
    return new Monocle.Controls.Contents(reader);
  }

  var API = { constructor: Monocle.Controls.Contents }
  var k = API.constants = API.constructor;
  var p = API.properties = {
    reader: reader
  }


  function createControlElements() {
    var div = reader.dom.make('div', 'controls_contents_container');
    contentsForBook(div, reader.getBook());
    return div;
  }


  function contentsForBook(div, book) {
    while (div.hasChildNodes()) {
      div.removeChild(div.firstChild);
    }
    var list = div.dom.append('ol', 'controls_contents_list');

    var contents = book.properties.contents;
    for (var i = 0; i < contents.length; ++i) {
      chapterBuilder(list, contents[i], 0);
    }
  }


  function chapterBuilder(list, chp, padLvl) {
    var index = list.childNodes.length;
    var li = list.dom.append('li', 'controls_contents_chapter', index);
    var span = li.dom.append(
      'span',
      'controls_contents_chapterTitle',
      index,
      { html: chp.title }
    );
    span.style.paddingLeft = padLvl + "em";

    var invoked = function () {
      p.reader.skipToChapter(chp.src);
      p.reader.hideControl(API);
    }

    Monocle.Events.listenForTap(li, invoked, 'controls_contents_chapter_active');

    if (chp.children) {
      for (var i = 0; i < chp.children.length; ++i) {
        chapterBuilder(list, chp.children[i], padLvl + 1);
      }
    }
  }


  API.createControlElements = createControlElements;

  return API;
}

Monocle.pieceLoaded('controls/contents');
Monocle.Controls.Magnifier = function (reader) {
  if (Monocle.Controls == this) {
    return new Monocle.Controls.Magnifier(reader);
  }

  // Public methods and properties.
  var API = { constructor: Monocle.Controls.Magnifier }
  var k = API.constants = API.constructor;
  var p = API.properties = {
    buttons: []
  }


  function initialize() {
    p.reader = reader;
  }


  function createControlElements(holder) {
    var btn = holder.dom.make('div', 'controls_magnifier_button');
    btn.smallA = btn.dom.append('span', 'controls_magnifier_a', { text: 'A' });
    btn.largeA = btn.dom.append('span', 'controls_magnifier_A', { text: 'A' });
    p.buttons.push(btn);
    Monocle.Events.listenForTap(btn, toggleMagnification);
    return btn;
  }


  function toggleMagnification(evt) {
    var opacities;
    if (!p.sheetIndex) {
      opacities = [0.3, 1]
      var reset = k.RESET_STYLESHEET;
      reset += "html body { font-size: "+k.MAGNIFICATION*100+"% !important; }";
      p.sheetIndex = p.reader.addPageStyles(reset);
    } else {
      opacities = [1, 0.3]
      p.reader.removePageStyles(p.sheetIndex);
      p.sheetIndex = null;
    }

    for (var i = 0; i < p.buttons.length; i++) {
      p.buttons[i].smallA.style.opacity = opacities[0];
      p.buttons[i].largeA.style.opacity = opacities[1];
    }
  }

  API.createControlElements = createControlElements;

  initialize();

  return API;
}


Monocle.Controls.Magnifier.MAGNIFICATION = 1.15;

// NB: If you don't like the reset, you could set this to an empty string.
Monocle.Controls.Magnifier.RESET_STYLESHEET =
  "html, body, div, span," +
  //"h1, h2, h3, h4, h5, h6, " +
  "p, blockquote, pre," +
  "abbr, address, cite, code," +
  "del, dfn, em, img, ins, kbd, q, samp," +
  "small, strong, sub, sup, var," +
  "b, i," +
  "dl, dt, dd, ol, ul, li," +
  "fieldset, form, label, legend," +
  "table, caption, tbody, tfoot, thead, tr, th, td," +
  "article, aside, details, figcaption, figure," +
  "footer, header, hgroup, menu, nav, section, summary," +
  "time, mark " +
  "{ font-size: 100% !important; }" +
  "h1 { font-size: 2em !important }" +
  "h2 { font-size: 1.8em !important }" +
  "h3 { font-size: 1.6em !important }" +
  "h4 { font-size: 1.4em !important }" +
  "h5 { font-size: 1.2em !important }" +
  "h6 { font-size: 1.0em !important }";

Monocle.pieceLoaded('controls/magnifier');
// A panel is an invisible column of interactivity. When contact occurs
// (mousedown, touchstart), the panel expands to the full width of its
// container, to catch all interaction events and prevent them from hitting
// other things.
//
// Panels are used primarily to provide hit zones for page flipping
// interactions, but you can do whatever you like with them.
//
// After instantiating a panel and adding it to the reader as a control,
// you can call listenTo() with a hash of methods for any of 'start', 'move'
// 'end' and 'cancel'.
//
Monocle.Controls.Panel = function () {

  var API = { constructor: Monocle.Controls.Panel }
  var k = API.constants = API.constructor;
  var p = API.properties = {
    evtCallbacks: {}
  }

  function createControlElements(cntr) {
    p.div = cntr.dom.make('div', k.CLS.panel);
    p.div.dom.setStyles(k.DEFAULT_STYLES);
    Monocle.Events.listenForContact(
      p.div,
      {
        'start': start,
        'move': move,
        'end': end,
        'cancel': cancel
      },
      { useCapture: false }
    );
    return p.div;
  }


  function listenTo(evtCallbacks) {
    p.evtCallbacks = evtCallbacks;
  }


  function deafen() {
    p.evtCallbacks = {}
  }


  function start(evt) {
    p.contact = true;
    evt.m.offsetX += p.div.offsetLeft;
    evt.m.offsetY += p.div.offsetTop;
    expand();
    invoke('start', evt);
  }


  function move(evt) {
    if (!p.contact) {
      return;
    }
    invoke('move', evt);
  }


  function end(evt) {
    if (!p.contact) {
      return;
    }
    Monocle.Events.deafenForContact(p.div, p.listeners);
    contract();
    p.contact = false;
    invoke('end', evt);
  }


  function cancel(evt) {
    if (!p.contact) {
      return;
    }
    Monocle.Events.deafenForContact(p.div, p.listeners);
    contract();
    p.contact = false;
    invoke('cancel', evt);
  }


  function invoke(evtType, evt) {
    if (p.evtCallbacks[evtType]) {
      p.evtCallbacks[evtType](API, evt.m.offsetX, evt.m.offsetY);
    }
    evt.preventDefault();
  }


  function expand() {
    if (p.expanded) {
      return;
    }
    p.div.dom.addClass(k.CLS.expanded);
    p.expanded = true;
  }


  function contract(evt) {
    if (!p.expanded) {
      return;
    }
    p.div.dom.removeClass(k.CLS.expanded);
    p.expanded = false;
  }


  API.createControlElements = createControlElements;
  API.listenTo = listenTo;
  API.deafen = deafen;
  API.expand = expand;
  API.contract = contract;

  return API;
}


Monocle.Controls.Panel.CLS = {
  panel: 'panel',
  expanded: 'controls_panel_expanded'
}
Monocle.Controls.Panel.DEFAULT_STYLES = {
  position: 'absolute',
  height: '100%'
}


Monocle.pieceLoaded('controls/panel');
Monocle.Controls.PlaceSaver = function (bookId) {
  if (Monocle.Controls == this) {
    return new Monocle.Controls.PlaceSaver(bookId);
  }

  var API = { constructor: Monocle.Controls.PlaceSaver }
  var k = API.constants = API.constructor;
  var p = API.properties = {}


  function initialize() {
    applyToBook(bookId);
  }


  function assignToReader(reader) {
    p.reader = reader;
    p.reader.listen('monocle:turn', savePlaceToCookie);
    p.reader.listen(
      'monocle:bookchange',
      function (evt) {
        applyToBook(evt.m.book.getMetaData('title'));
      }
    );
  }


  function applyToBook(bookId) {
    p.bkTitle = bookId.toLowerCase().replace(/[^a-z0-9]/g, '');
    p.prefix = k.COOKIE_NAMESPACE + p.bkTitle + ".";
  }


  function setCookie(key, value, days) {
    var expires = "";
    if (days) {
      var d = new Date();
      d.setTime(d.getTime() + (days * 24 * 60 * 60 * 1000));
      expires = "; expires="+d.toGMTString();
    }
    var path = "; path=/";
    document.cookie = p.prefix + key + " = " + value + expires + path;
    return value;
  }


  function getCookie(key) {
    if (!document.cookie) {
      return null;
    }
    var regex = new RegExp(p.prefix + key + "=(.+?)(;|$)");
    var matches = document.cookie.match(regex);
    if (matches) {
      return matches[1];
    } else {
      return null;
    }
  }


  function savePlaceToCookie() {
    var place = p.reader.getPlace();
    setCookie(
      "component",
      encodeURIComponent(place.componentId()),
      k.COOKIE_EXPIRES_IN_DAYS
    );
    setCookie(
      "percent",
      place.percentageThrough(),
      k.COOKIE_EXPIRES_IN_DAYS
    );
  }


  function savedPlace() {
    var locus = {
      componentId: getCookie('component'),
      percent: getCookie('percent')
    }
    if (locus.componentId && locus.percent) {
      locus.componentId = decodeURIComponent(locus.componentId);
      locus.percent = parseFloat(locus.percent);
      return locus;
    } else {
      return null;
    }
  }


  function restorePlace() {
    var locus = savedPlace();
    if (locus) {
      p.reader.moveTo(locus);
    }
  }


  API.assignToReader = assignToReader;
  API.savedPlace = savedPlace;
  API.restorePlace = restorePlace;

  initialize();

  return API;
}

Monocle.Controls.PlaceSaver.COOKIE_NAMESPACE = "monocle.controls.placesaver.";
Monocle.Controls.PlaceSaver.COOKIE_EXPIRES_IN_DAYS = 7; // Set to 0 for session-based expiry.


Monocle.pieceLoaded('controls/placesaver');
Monocle.Controls.Scrubber = function (reader) {
  if (Monocle.Controls == this) {
    return new Monocle.Controls.Scrubber(reader);
  }

  var API = { constructor: Monocle.Controls.Scrubber }
  var k = API.constants = API.constructor;
  var p = API.properties = {}


  function initialize() {
    p.reader = reader;
    p.reader.listen('monocle:turn', updateNeedles);
    updateNeedles();
  }


  function pixelToPlace(x, cntr) {
    if (!p.componentIds) {
      p.componentIds = p.reader.getBook().properties.componentIds;
      p.componentWidth = 100 / p.componentIds.length;
    }
    var pc = (x / cntr.offsetWidth) * 100;
    var cmpt = p.componentIds[Math.floor(pc / p.componentWidth)];
    var cmptPc = ((pc % p.componentWidth) / p.componentWidth);
    return { componentId: cmpt, percentageThrough: cmptPc };
  }


  function placeToPixel(place, cntr) {
    if (!p.componentIds) {
      p.componentIds = p.reader.getBook().properties.componentIds;
      p.componentWidth = 100 / p.componentIds.length;
    }
    var componentIndex = p.componentIds.indexOf(place.componentId());
    var pc = p.componentWidth * componentIndex;
    pc += place.percentageThrough() * p.componentWidth;
    return Math.round((pc / 100) * cntr.offsetWidth);
  }


  function updateNeedles() {
    if (p.hidden || !p.reader.dom.find(k.CLS.container)) {
      return;
    }
    var place = p.reader.getPlace();
    var x = placeToPixel(place, p.reader.dom.find(k.CLS.container));
    var needle, i = 0;
    for (var i = 0, needle; needle = p.reader.dom.find(k.CLS.needle, i); ++i) {
      setX(needle, x - needle.offsetWidth / 2);
      p.reader.dom.find(k.CLS.trail, i).style.width = x + "px";
    }
  }


  function setX(node, x) {
    var cntr = p.reader.dom.find(k.CLS.container);
    x = Math.min(cntr.offsetWidth - node.offsetWidth, x);
    x = Math.max(x, 0);
    Monocle.Styles.setX(node, x);
  }


  function createControlElements(holder) {
    var cntr = holder.dom.make('div', k.CLS.container);
    var track = cntr.dom.append('div', k.CLS.track);
    var needleTrail = cntr.dom.append('div', k.CLS.trail);
    var needle = cntr.dom.append('div', k.CLS.needle);
    var bubble = cntr.dom.append('div', k.CLS.bubble);

    var cntrListeners, bodyListeners;

    var moveEvt = function (evt, x) {
      evt.preventDefault();
      x = (typeof x == "number") ? x : evt.m.registrantX;
      var place = pixelToPlace(x, cntr);
      setX(needle, x - needle.offsetWidth / 2);
      var book = p.reader.getBook();
      var chps = book.chaptersForComponent(place.componentId);
      var cmptIndex = p.componentIds.indexOf(place.componentId);
      var chp = chps[Math.floor(chps.length * place.percentageThrough)];
      if (cmptIndex > -1 && book.properties.components[cmptIndex]) {
        var actualPlace = Monocle.Place.FromPercentageThrough(
          book.properties.components[cmptIndex],
          place.percentageThrough
        );
        chp = actualPlace.chapterInfo() || chp;
      }

      if (chp) {
        bubble.innerHTML = chp.title;
      }
      setX(bubble, x - bubble.offsetWidth / 2);

      p.lastX = x;
      return place;
    }

    var endEvt = function (evt) {
      var place = moveEvt(evt, p.lastX);
      p.reader.moveTo({
        percent: place.percentageThrough,
        componentId: place.componentId
      });
      Monocle.Events.deafenForContact(cntr, cntrListeners);
      Monocle.Events.deafenForContact(document.body, bodyListeners);
      bubble.style.display = "none";
    }

    var startFn = function (evt) {
      bubble.style.display = "block";
      moveEvt(evt);
      cntrListeners = Monocle.Events.listenForContact(
        cntr,
        { move: moveEvt }
      );
      bodyListeners = Monocle.Events.listenForContact(
        document.body,
        { end: endEvt }
      );
    }

    Monocle.Events.listenForContact(cntr, { start: startFn });

    return cntr;
  }


  API.createControlElements = createControlElements;
  API.updateNeedles = updateNeedles;

  initialize();

  return API;
}

Monocle.Controls.Scrubber.CLS = {
  container: 'controls_scrubber_container',
  track: 'controls_scrubber_track',
  needle: 'controls_scrubber_needle',
  trail: 'controls_scrubber_trail',
  bubble: 'controls_scrubber_bubble'
}

Monocle.pieceLoaded('controls/scrubber');
Monocle.Controls.Spinner = function (reader) {
  if (Monocle.Controls == this) {
    return new Monocle.Controls.Spinner(reader);
  }

  var API = { constructor: Monocle.Controls.Spinner }
  var k = API.constants = API.constructor;
  var p = API.properties = {
    reader: reader,
    divs: [],
    spinCount: 0,
    repeaters: {},
    showForPages: []
  }


  function createControlElements(cntr) {
    var anim = cntr.dom.make('div', 'controls_spinner_anim');
    p.divs.push(anim);
    return anim;
  }


  function registerSpinEvt(startEvtType, stopEvtType) {
    var label = startEvtType;
    p.reader.listen(startEvtType, function (evt) { spin(label, evt) });
    p.reader.listen(stopEvtType, function (evt) { spun(label, evt) });
  }


  // Registers spin/spun event handlers for certain time-consuming events.
  //
  function listenForUsualDelays() {
    registerSpinEvt('monocle:componentloading', 'monocle:componentloaded');
    registerSpinEvt('monocle:componentchanging', 'monocle:componentchange');
    registerSpinEvt('monocle:resizing', 'monocle:resize');
    registerSpinEvt('monocle:jumping', 'monocle:jump');
    registerSpinEvt('monocle:recalculating', 'monocle:recalculated');
  }


  // Displays the spinner. Both arguments are optional.
  //
  function spin(label, evt) {
    label = label || k.GENERIC_LABEL;
    //console.log('Spinning on ' + (evt ? evt.type : label));
    p.repeaters[label] = true;
    p.reader.showControl(API);

    // If the delay is on a page other than the page we've been assigned to,
    // don't show the animation. p.global ensures that if an event affects
    // all pages, the animation is always shown, even if other events in this
    // spin cycle are page-specific.
    var page = evt && evt.m && evt.m.page ? evt.m.page : null;
    if (!page) { p.global = true; }
    for (var i = 0; i < p.divs.length; ++i) {
      var owner = p.divs[i].parentNode.parentNode;
      if (page == owner) { p.showForPages.push(page); }
      var show = p.global || p.showForPages.indexOf(page) >= 0;
      p.divs[i].style.display = show ? 'block' : 'none';
    }
  }


  // Stops displaying the spinner. Both arguments are optional.
  //
  function spun(label, evt) {
    label = label || k.GENERIC_LABEL;
    //console.log('Spun on ' + (evt ? evt.type : label));
    p.repeaters[label] = false;
    for (var l in p.repeaters) {
      if (p.repeaters[l]) { return; }
    }
    p.global = false;
    p.showForPages = [];
    p.reader.hideControl(API);
  }


  API.createControlElements = createControlElements;
  API.listenForUsualDelays = listenForUsualDelays;
  API.spin = spin;
  API.spun = spun;

  return API;
}

Monocle.Controls.Spinner.GENERIC_LABEL = "generic";
Monocle.pieceLoaded('controls/spinner');
Monocle.Controls.Stencil = function (reader) {

  if (Monocle.Controls == this) { return new this.Stencil(reader); }

  var API = { constructor: Monocle.Controls.Stencil }
  var k = API.constants = API.constructor;
  var p = API.properties = {
    reader: reader,
    activeComponent: null,
    components: {},
    cutouts: []
  }


  // Create the stencil container and listen for draw/update events.
  //
  function createControlElements(holder) {
    p.container = holder.dom.make('div', k.CLS.container);
    p.reader.listen('monocle:turn', update);
    p.reader.listen('monocle:stylesheetchange', update);
    p.reader.listen('monocle:resize', update);
    p.reader.listen('monocle:interactive:on', disable);
    p.reader.listen('monocle:interactive:off', enable);
    p.baseURL = getBaseURL();
    update();
    return p.container;
  }


  // Resets any pre-calculated rectangles for the active component,
  // recalculates them, and forces cutouts to be "drawn" (moved into the new
  // rectangular locations).
  //
  function update() {
    var pageDiv = p.reader.visiblePages()[0];
    var cmptId = pageComponentId(pageDiv);
    p.components[cmptId] = null;
    calculateRectangles(pageDiv);
    draw();
  }


  // Aligns the stencil container to the shape of the page, then moves the
  // cutout links to sit above any currently visible rectangles.
  //
  function draw() {
    var pageDiv = p.reader.visiblePages()[0];
    var cmptId = pageComponentId(pageDiv);
    if (!p.components[cmptId]) {
      return;
    }

    // Position the container.
    alignToComponent(pageDiv);

    // Layout the cutouts.
    var placed = 0;
    if (!p.disabled) {
      var rects = p.components[cmptId];
      if (rects && rects.length) {
        placed = layoutRectangles(pageDiv, rects);
      }
    }

    // Hide remaining rects.
    while (placed < p.cutouts.length) {
      hideCutout(placed);
      placed += 1;
    }
  }


  // Iterate over all the <a> elements in the active component, and
  // create an array of rectangular points corresponding to their positions.
  //
  function calculateRectangles(pageDiv) {
    var cmptId = pageComponentId(pageDiv);
    p.activeComponent = cmptId;
    var doc = pageDiv.m.activeFrame.contentDocument;
    var offset = getOffset(pageDiv);
    // BROWSERHACK: Gecko doesn't subtract translations from GBCR values.
    if (Monocle.Browser.is.Gecko) {
      offset.l = 0;
    }
    var calcRects = false;
    if (!p.components[cmptId]) {
      p.components[cmptId] = []
      calcRects = true;
    }

    var links = doc.getElementsByTagName('a');
    for (var i = 0; i < links.length; ++i) {
      var link = links[i];
      if (link.href) {
        var hrefObject = deconstructHref(link.href);
        link.setAttribute('target', '_blank');
        link.deconstructedHref = hrefObject;
        if (hrefObject.external) {
          link.href = hrefObject.external;
        } else if (link.relatedLink) {
          link.removeAttribute('href');
        }

        if (calcRects && link.getClientRects) {
          var r = link.getClientRects();
          for (var j = 0; j < r.length; j++) {
            p.components[cmptId].push({
              link: link,
              href: hrefObject,
              left: Math.ceil(r[j].left + offset.l),
              top: Math.ceil(r[j].top),
              width: Math.floor(r[j].width),
              height: Math.floor(r[j].height)
            });
          }
        }
      }
    }

    return p.components[cmptId];
  }


  // Find the offset position in pixels from the left of the current page.
  //
  function getOffset(pageDiv) {
    return {
      l: pageDiv.m.offset || 0,
      w: pageDiv.m.dimensions.properties.width
    };
  }


  // Update location of visible rectangles - creating as required.
  //
  function layoutRectangles(pageDiv, rects) {
    var offset = getOffset(pageDiv);
    var visRects = [];
    for (var i = 0; i < rects.length; ++i) {
      if (rectVisible(rects[i], offset.l, offset.l + offset.w)) {
        visRects.push(rects[i]);
      }
    }

    for (i = 0; i < visRects.length; ++i) {
      if (!p.cutouts[i]) {
        p.cutouts[i] = createCutout();
      }
      var cutout = p.cutouts[i];
      cutout.dom.setStyles({
        display: 'block',
        left: (visRects[i].left - offset.l)+"px",
        top: visRects[i].top+"px",
        width: visRects[i].width+"px",
        height: visRects[i].height+"px"
      });
      cutout.relatedLink = visRects[i].link;
      var extURL = visRects[i].href.external;
      if (extURL) {
        cutout.setAttribute('href', extURL);
      } else {
        cutout.removeAttribute('href');
      }
    }

    return i;
  }


  function createCutout() {
    var cutout =  p.container.dom.append('a', k.CLS.cutout);
    cutout.setAttribute('target', '_blank');
    Monocle.Events.listen(cutout, 'click', cutoutClick);
    return cutout;
  }


  // Returns the active component id for the given page, or the current
  // page if no argument passed in.
  //
  function pageComponentId(pageDiv) {
    pageDiv = pageDiv || p.reader.visiblePages()[0];
    return pageDiv.m.activeFrame.m.component.properties.id;
  }


  // Positions the stencil container over the active frame.
  //
  function alignToComponent(pageDiv) {
    cmpt = pageDiv.m.activeFrame.parentNode;
    p.container.dom.setStyles({
      top: cmpt.offsetTop + "px",
      left: cmpt.offsetLeft + "px"
    });
  }


  function hideCutout(index) {
    p.cutouts[index].dom.setStyles({ display: 'none' });
  }


  function rectVisible(rect, l, r) {
    return rect.left >= l && rect.left < r;
  }


  // Make the active cutouts visible (by giving them a class -- override style
  // in monocle.css).
  //
  function toggleHighlights() {
    var cls = k.CLS.highlights
    if (p.container.dom.hasClass(cls)) {
      p.container.dom.removeClass(cls);
    } else {
      p.container.dom.addClass(cls);
    }
  }


  // Returns an object with either:
  //
  // - an 'external' property -- an absolute URL with a protocol,
  // host & etc, which should be treated as an external resource (eg,
  // open in new window)
  //
  //   OR
  //
  // - a 'componentId' property -- a relative URL with no forward slash,
  // which must be treated as a componentId; and
  // - a 'hash' property -- which may be an anchor in the form "#foo", or
  // may be blank.
  //
  // Expects an absolute URL to be passed in. A weird but useful property
  // of <a> tags is that while link.getAttribute('href') will return the
  // actual string value of the attribute (eg, 'foo.html'), link.href will
  // return the absolute URL (eg, 'http://example.com/monocles/foo.html').
  //
  function deconstructHref(url) {
    var result = {};
    var re = new RegExp("^"+p.baseURL+"([^#]*)(#.*)?$");
    var match = url.match(re);
    if (match) {
      result.componentId = match[1] || pageComponentId();
      result.hash = match[2] || '';
    } else {
      result.external = url;
    }
    return result;
  }


  // Returns the base URL for the reader's host page, which can be used
  // to deconstruct the hrefs of individual links within components.
  //
  function getBaseURL() {
    var a = document.createElement('a');
    a.setAttribute('href', 'x');
    return a.href.replace(/x$/,'')
  }


  // Invoked when a cutout is clicked -- opens external URL in new window,
  // or moves to an internal component.
  //
  function cutoutClick(evt) {
    var cutout = evt.currentTarget;
    if (cutout.getAttribute('href')) { return; }
    var olink = cutout.relatedLink;
    Monocle.Events.listen(olink, 'click', clickHandler);
    var mimicEvt = document.createEvent('MouseEvents');
    mimicEvt.initMouseEvent(
      'click',
      true,
      true,
      document.defaultView,
      evt.detail,
      evt.screenX,
      evt.screenY,
      evt.screenX,
      evt.screenY,
      evt.ctrlKey,
      evt.altKey,
      evt.shiftKey,
      evt.metaKey,
      evt.which,
      null
    );
    try {
      olink.dispatchEvent(mimicEvt);
    } finally {
      Monocle.Events.deafen(olink, 'click', clickHandler);
    }
  }


  function clickHandler(evt) {
    if (evt.defaultPrevented) { // NB: unfortunately not supported in Gecko.
      return;
    }
    var link = evt.currentTarget;
    var hrefObject = link.deconstructedHref;
    if (!hrefObject) {
      return;
    }
    if (hrefObject.external) {
      return;
    }
    var cmptId = hrefObject.componentId + hrefObject.hash;
    p.reader.skipToChapter(cmptId);
    evt.preventDefault();
  }


  function disable() {
    p.disabled = true;
    draw();
  }


  function enable() {
    p.disabled = false;
    draw();
  }


  API.createControlElements = createControlElements;
  API.draw = draw;
  API.update = update;
  API.toggleHighlights = toggleHighlights;

  return API;
}


Monocle.Controls.Stencil.CLS = {
  container: 'controls_stencil_container',
  cutout: 'controls_stencil_cutout',
  highlights: 'controls_stencil_highlighted'
}


Monocle.pieceLoaded('controls/stencil');

Monocle.pieceLoaded('monoctrl');
