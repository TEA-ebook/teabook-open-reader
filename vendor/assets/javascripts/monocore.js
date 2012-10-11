Monocle = {
  VERSION: "2.3.1"
};


Monocle.pieceLoaded = function (piece) {
  if (typeof onMonoclePiece == 'function') {
    onMonoclePiece(piece);
  }
}


Monocle.defer = function (fn, time) {
  if (fn && typeof fn == "function") {
    return setTimeout(fn, time || 0);
  }
}

Monocle.Dimensions = {}
Monocle.Controls = {};
Monocle.Flippers = {};
Monocle.Panels = {};


Monocle.pieceLoaded("core/monocle");
Monocle.Env = function () {

  var API = { constructor: Monocle.Env }
  var k = API.constants = API.constructor;
  var p = API.properties = {
    // Assign to a function before running survey in order to get
    // results as they come in. The function should take two arguments:
    // testName and value.
    resultCallback: null
  }

  // These are private variables so they don't clutter up properties.
  var css = Monocle.Browser.css;
  var activeTestName = null;
  var frameLoadCallback = null;
  var testFrame = null;
  var testFrameCntr = null;
  var testFrameSize = 100;
  var surveyCallback = null;


  function survey(cb) {
    surveyCallback = cb;
    runNextTest();
  }


  function runNextTest() {
    var test = envTests.shift();
    if (!test) { return completed(); }
    activeTestName = test[0];
    try { test[1](); } catch (e) { result(e); }
  }


  // Each test should call this to say "I'm finished, run the next test."
  //
  function result(val) {
    //console.log("["+activeTestName+"] "+val);
    API[activeTestName] = val;
    if (p.resultCallback) { p.resultCallback(activeTestName, val); }
    runNextTest();
    return val;
  }


  // Invoked after all tests have run.
  //
  function completed() {
    // Remove the test frame after a slight delay (otherwise Gecko spins).
    Monocle.defer(removeTestFrame);

    if (typeof surveyCallback == "function") {
      surveyCallback(API);
    }
  }


  // A bit of sugar for simplifying a detection pattern: does this
  // function exist?
  //
  // Pass a string snippet of JavaScript to be evaluated.
  //
  function testForFunction(str) {
    return function () { result(typeof eval(str) == "function"); }
  }


  // A bit of sugar to indicate that the detection function for this test
  // hasn't been written yet...
  //
  // Pass the value you want assigned for the test until it is implemented.
  //
  function testNotYetImplemented(rslt) {
    return function () { result(rslt); }
  }



  // Loads (or reloads) a hidden iframe so that we can test browser features.
  //
  // cb is the callback that is fired when the test frame's content is loaded.
  //
  // src is optional, in which case it defaults to 4. If provided, it can be
  // a number (specifying the number of pages of default content), or a string,
  // which will be loaded as a URL.
  //
  function loadTestFrame(cb, src) {
    if (!testFrame) { testFrame = createTestFrame(); }
    frameLoadCallback = cb;

    src = src || 4;

    if (typeof src == "number") {
      var pgs = [];
      for (var i = 1, ii = src; i <= ii; ++i) {
        pgs.push("<div>Page "+i+"</div>");
      }
      var divStyle = [
        "display:inline-block",
        "line-height:"+testFrameSize+"px",
        "width:"+testFrameSize+"px"
      ].join(";");
      src = "javascript:'<!DOCTYPE html><html>"+
        '<head><meta name="time" content="'+(new Date()).getTime()+'" />'+
        '<style>div{'+divStyle+'}</style></head>'+
        '<body>'+pgs.join("")+'</body>'+
        "</html>'";
    }

    testFrame.src = src;
  }


  // Creates the hidden test frame and returns it.
  //
  function createTestFrame() {
    testFrameCntr = document.createElement('div');
    testFrameCntr.style.cssText = [
      "width:"+testFrameSize+"px",
      "height:"+testFrameSize+"px",
      "overflow:hidden",
      "position:absolute",
      "visibility:hidden"
    ].join(";");
    document.body.appendChild(testFrameCntr);

    var fr = document.createElement('iframe');
    testFrameCntr.appendChild(fr);
    fr.setAttribute("scrolling", "no");
    fr.style.cssText = [
      "width:100%",
      "height:100%",
      "border:none",
      "background:#900"
    ].join(";");
    fr.addEventListener(
      "load",
      function () {
        if (!fr.contentDocument || !fr.contentDocument.body) { return; }
        var bd = fr.contentDocument.body;
        bd.style.cssText = ([
          "margin:0",
          "padding:0",
          "position:absolute",
          "height:100%",
          "width:100%",
          "-webkit-column-width:"+testFrameSize+"px",
          "-webkit-column-gap:0",
          "-webkit-column-fill:auto",
          "-moz-column-width:"+testFrameSize+"px",
          "-moz-column-gap:0",
          "-moz-column-fill:auto",
          "-o-column-width:"+testFrameSize+"px",
          "-o-column-gap:0",
          "-o-column-fill:auto",
          "column-width:"+testFrameSize+"px",
          "column-gap:0",
          "column-fill:auto"
        ].join(";"));
        if (bd.scrollHeight > testFrameSize) {
          bd.style.cssText += ["min-width:200%", "overflow:hidden"].join(";");
          if (bd.scrollHeight <= testFrameSize) {
            bd.className = "column-force";
          } else {
            bd.className = "column-failed "+bd.scrollHeight;
          }
        }
        frameLoadCallback(fr);
      },
      false
    );
    return fr;
  }


  function removeTestFrame() {
    if (testFrameCntr && testFrameCntr.parentNode) {
      testFrameCntr.parentNode.removeChild(testFrameCntr);
    }
  }


  function columnedWidth(fr) {
    var bd = fr.contentDocument.body;
    var de = fr.contentDocument.documentElement;
    return Math.max(bd.scrollWidth, de.scrollWidth);
  }


  var envTests = [

    // TEST FOR REQUIRED CAPABILITIES

    ["supportsW3CEvents", testForFunction("window.addEventListener")],
    ["supportsCustomEvents", testForFunction("document.createEvent")],
    ["supportsColumns", function () {
      result(css.supportsPropertyWithAnyPrefix('column-width'));
    }],
    ["supportsTransform", function () {
      result(css.supportsProperty([
        'transformProperty',
        'WebkitTransform',
        'MozTransform',
        'OTransform',
        'msTransform'
      ]));
    }],


    // TEST FOR OPTIONAL CAPABILITIES

    // Does it do CSS transitions?
    ["supportsTransition", function () {
      result(css.supportsPropertyWithAnyPrefix('transition'))
    }],

    // Can we find nodes in a document with an XPath?
    //
    ["supportsXPath", testForFunction("document.evaluate")],

    // Can we find nodes in a document natively with a CSS selector?
    //
    ["supportsQuerySelector", testForFunction("document.querySelector")],

    // Can we do 3d transforms?
    //
    ["supportsTransform3d", function () {
      result(
        css.supportsMediaQueryProperty('transform-3d') &&
        css.supportsProperty([
          'perspectiveProperty',
          'WebkitPerspective',
          'MozPerspective',
          'OPerspective',
          'msPerspective'
        ])
      );
    }],


    // CHECK OUT OUR CONTEXT

    // Does the device have a MobileSafari-style touch interface?
    //
    ["touch", function () {
      result(
        ('ontouchstart' in window) ||
        css.supportsMediaQueryProperty('touch-enabled')
      );
    }],

    // Is the Reader embedded, or in the top-level window?
    //
    ["embedded", function () { result(top != self) }],


    // TEST FOR CERTAIN RENDERING OR INTERACTION BUGS

    // iOS (at least up to version 4.1) makes a complete hash of touch events
    // when an iframe is overlapped by other elements. It's a dog's breakfast.
    // See test/bugs/ios-frame-touch-bug for details.
    //
    ["brokenIframeTouchModel", function () {
      result(Monocle.Browser.iOSVersionBelow("4.2"));
    }],

    // In early versions of iOS (up to 4.1), MobileSafari would send text-select
    // activity to the first iframe, even if that iframe is overlapped by a
    // "higher" iframe.
    //
    ["selectIgnoresZOrder", function () {
      result(Monocle.Browser.iOSVersionBelow("4.2"));
    }],

    // Webkit-based browsers put floated elements in the wrong spot when
    // columns are used -- they appear way down where they would be if there
    // were no columns.  Presumably the float positions are calculated before
    // the columns. A bug has been lodged, and it's fixed in recent WebKits.
    //
    ["floatsIgnoreColumns", function () {
      if (!Monocle.Browser.is.WebKit) { return result(false); }
      match = navigator.userAgent.match(/AppleWebKit\/([\d\.]+)/);
      if (!match) { return result(false); }
      return result(match[1] < "534.30");
    }],

    // The latest engines all agree that if a body is translated leftwards,
    // its scrollWidth is shortened. But some older WebKits (notably iOS4)
    // do not subtract translateX values from scrollWidth. In this case,
    // we should not add the translate back when calculating the width.
    //
    ["widthsIgnoreTranslate", function () {
      loadTestFrame(function (fr) {
        var firstWidth = columnedWidth(fr);
        var s = fr.contentDocument.body.style;
        var props = css.toDOMProps("transform");
        for (var i = 0, ii = props.length; i < ii; ++i) {
          s[props[i]] = "translateX(-600px)";
        }
        var secondWidth = columnedWidth(fr);
        for (i = 0, ii = props.length; i < ii; ++i) {
          s[props[i]] = "none";
        }
        result(secondWidth == firstWidth);
      });
    }],

    // On Android browsers, if the component iframe has a relative width (ie,
    // 100%), the width of the entire browser will keep expanding and expanding
    // to fit the width of the body of the iframe (which, with columns, is
    // massive). So, 100% is treated as "of the body content" rather than "of
    // the parent dimensions". In this scenario, we need to give the component
    // iframe a fixed width in pixels.
    //
    // In iOS, the frame is clipped by overflow:hidden, so this doesn't seem to
    // be a problem.
    //
    ["relativeIframeExpands", function () {
      result(navigator.userAgent.indexOf("Android 2") >= 0);
    }],

    // iOS3 will pause JavaScript execution if it gets a style-change + a
    // scroll change on a component body. Weirdly, this seems to break GBCR
    // in iOS4.
    //
    ["scrollToApplyStyle", function () {
      result(Monocle.Browser.iOSVersionBelow("4"));
    }],


    // TEST FOR OTHER QUIRKY BROWSER BEHAVIOUR

    // Older versions of WebKit (iOS3, Kindle3) need a min-width set on the
    // body of the iframe at 200%. This forces columns. But when this
    // min-width is set, it's more difficult to recognise 1 page components,
    // so we generally don't want to force it unless we have to.
    //
    ["forceColumns", function () {
      loadTestFrame(function (fr) {
        var bd = fr.contentDocument.body;
        result(bd.className ? true : false);
      });
    }],

    // A component iframe's body is absolutely positioned. This means that
    // the documentElement should have a height of 0, since it contains nothing
    // other than an absolutely positioned element.
    //
    // But for some browsers (Gecko and Opera), the documentElement is as
    // wide as the full columned content, and the body is only as wide as
    // the iframe element (ie, the first column).
    //
    // It gets weirder. Gecko sometimes behaves like WebKit (not clipping the
    // body) IF the component has been loaded via HTML/JS/Nodes, not URL. Still
    // can't reproduce outside Monocle.
    //
    // FIXME: If we can figure out a reliable behaviour for Gecko, we should
    // use it to precalculate the workaround. At the moment, this test isn't
    // used, but it belongs in src/dimensions/columns.js#columnedDimensions().
    //
    // ["iframeBodyWidthClipped", function () {
    //   loadTestFrame(function (fr) {
    //     var doc = fr.contentDocument;
    //     result(
    //       doc.body.scrollWidth <= testFrameSize &&
    //       doc.documentElement.scrollWidth > testFrameSize
    //     );
    //   })
    // }],

    // Finding the page that a given HTML node is on is typically done by
    // calculating the offset of its rectange from the body's rectangle.
    //
    // But if this information isn't provided by the browser, we need to use
    // node.scrollIntoView and check the scrollOffset. Basically iOS3 is the
    // only target platform that doesn't give us the rectangle info.
    //
    ["findNodesByScrolling", function () {
      result(typeof document.body.getBoundingClientRect !== "function");
    }],

    // In MobileSafari browsers, iframes are rendered at the width and height
    // of their content, rather than having scrollbars. So in that case, it's
    // the containing element (the "sheaf") that must be scrolled, not the
    // iframe body.
    //
    ["sheafIsScroller", function () {
      loadTestFrame(function (fr) {
        result(fr.parentNode.scrollWidth > testFrameSize);
      });
    }],

    // For some reason, iOS MobileSafari sometimes loses track of a page after
    // slideOut -- it thinks it has an x-translation of 0, rather than -768 or
    // whatever. So the page gets "stuck" there, until it is given a non-zero
    // x-translation. The workaround is to set a non-zero duration on the jumpIn,
    // which seems to force WebKit to recalculate the x of the page. Weird, yeah.
    //
    ["stickySlideOut", function () {
      result(Monocle.Browser.is.MobileSafari);
    }]

  ];


  function isCompatible() {
    return (
      API.supportsW3CEvents &&
      API.supportsCustomEvents &&
      // API.supportsColumns &&     // This is coming in 3.0!
      API.supportsTransform
    );
  }


  API.survey = survey;
  API.isCompatible = isCompatible;

  return API;
}



Monocle.pieceLoaded('compat/env');
Monocle.CSS = function () {

  var API = { constructor: Monocle.CSS }
  var k = API.constants = API.constructor;
  var p = API.properties = {
    guineapig: document.createElement('div')
  }


  // Returns engine-specific properties,
  //
  // eg:
  //
  //  toCSSProps('transform')
  //
  // ... in WebKit, this will return:
  //
  //  ['transform', '-webkit-transform']
  //
  function toCSSProps(prop) {
    var props = [prop];
    var eng = k.engines.indexOf(Monocle.Browser.engine);
    if (eng) {
      var pf = k.prefixes[eng];
      if (pf) {
        props.push(pf+prop);
      }
    }
    return props;
  }


  // Returns an engine-specific CSS string.
  //
  // eg:
  //
  //   toCSSDeclaration('column-width', '300px')
  //
  // ... in Mozilla, this will return:
  //
  //   "column-width: 300px; -moz-column-width: 300px;"
  //
  function toCSSDeclaration(prop, val) {
    var props = toCSSProps(prop);
    for (var i = 0, ii = props.length; i < ii; ++i) {
      props[i] += ": "+val+";";
    }
    return props.join("");
  }


  // Returns an array of DOM properties specific to this engine.
  //
  // eg:
  //
  //   toDOMProps('column-width')
  //
  // ... in Opera, this will return:
  //
  //   [columnWidth, OColumnWidth]
  //
  function toDOMProps(prop) {
    var parts = prop.split('-');
    for (var i = parts.length; i > 0; --i) {
      parts[i] = capStr(parts[i]);
    }

    var props = [parts.join('')];
    var eng = k.engines.indexOf(Monocle.Browser.engine);
    if (eng) {
      var pf = k.domprefixes[eng];
      if (pf) {
        parts[0] = capStr(parts[0]);
        props.push(pf+parts.join(''));
      }
    }
    return props;
  }


  // Is this exact property (or any in this array of properties) supported
  // by this engine?
  //
  function supportsProperty(props) {
    for (var i in props) {
      if (p.guineapig.style[props[i]] !== undefined) { return true; }
    }
    return false;
  } // Thanks modernizr!



  // Is this property (or a prefixed variant) supported by this engine?
  //
  function supportsPropertyWithAnyPrefix(prop) {
    return supportsProperty(toDOMProps(prop));
  }


  function supportsMediaQuery(query) {
    var gpid = "monocle_guineapig";
    p.guineapig.id = gpid;
    var st = document.createElement('style');
    st.textContent = query+'{#'+gpid+'{height:3px}}';
    (document.head || document.getElementsByTagName('head')[0]).appendChild(st);
    document.documentElement.appendChild(p.guineapig);

    var result = p.guineapig.offsetHeight === 3;

    st.parentNode.removeChild(st);
    p.guineapig.parentNode.removeChild(p.guineapig);

    return result;
  } // Thanks modernizr!


  function supportsMediaQueryProperty(prop) {
    return supportsMediaQuery(
      '@media (' + k.prefixes.join(prop+'),(') + 'monocle__)'
    );
  }


  function capStr(wd) {
    return wd ? wd.charAt(0).toUpperCase() + wd.substr(1) : "";
  }


  API.toCSSProps = toCSSProps;
  API.toCSSDeclaration = toCSSDeclaration;
  API.toDOMProps = toDOMProps;
  API.supportsProperty = supportsProperty;
  API.supportsPropertyWithAnyPrefix = supportsPropertyWithAnyPrefix;
  API.supportsMediaQuery = supportsMediaQuery;
  API.supportsMediaQueryProperty = supportsMediaQueryProperty;

  return API;
}


Monocle.CSS.engines = ["W3C", "WebKit", "Gecko", "Opera", "IE", "Konqueror"];
Monocle.CSS.prefixes = ["", "-webkit-", "-moz-", "-o-", "-ms-", "-khtml-"];
Monocle.CSS.domprefixes = ["", "Webkit", "Moz", "O", "ms", "Khtml"];


Monocle.pieceLoaded('compat/css');
// STUBS - simple debug functions and polyfills to normalise client
// execution environments.


// A little console stub if not initialized in a console-equipped browser.
//
if (typeof window.console == "undefined") {
  window.console = {
    messages: [],
    log: function (msg) {
      this.messages.push(msg);
    }
  }
}


// A simple version of console.dir that works on iOS.
//
window.console.compatDir = function (obj) {
  var stringify = function (o) {
    var parts = [];
    for (x in o) {
      parts.push(x + ": " + o[x]);
    }
    return parts.join("; ");
  }

  window.console.log(stringify(obj));
}


Monocle.pieceLoaded('compat/stubs');
Monocle.Browser = {}

// Detect the browser engine and set boolean flags for reference.
//
Monocle.Browser.is = {
  IE: !!(window.attachEvent && navigator.userAgent.indexOf('Opera') === -1),
  Opera: navigator.userAgent.indexOf('Opera') > -1,
  WebKit: navigator.userAgent.indexOf('AppleWebKit') > -1,
  Gecko: navigator.userAgent.indexOf('Gecko') > -1 &&
    navigator.userAgent.indexOf('KHTML') === -1,
  MobileSafari: !!navigator.userAgent.match(/AppleWebKit.*Mobile/)
} // ... with thanks to PrototypeJS.


if (Monocle.Browser.is.IE) {
  Monocle.Browser.engine = "IE";
} else if (Monocle.Browser.is.Opera) {
  Monocle.Browser.engine = "Opera";
} else if (Monocle.Browser.is.WebKit) {
  Monocle.Browser.engine = "WebKit";
} else if (Monocle.Browser.is.Gecko) {
  Monocle.Browser.engine = "Gecko";
} else {
  Monocle.Browser.engine = "W3C";
}


// Detect the client platform (typically device/operating system).
//
Monocle.Browser.on = {
  iPhone: Monocle.Browser.is.MobileSafari && screen.width == 320,
  iPad: Monocle.Browser.is.MobileSafari && screen.width == 768,
  UIWebView: Monocle.Browser.is.MobileSafari &&
    navigator.userAgent.indexOf("Safari") < 0 &&
    !navigator.standalone,
  BlackBerry: navigator.userAgent.indexOf("BlackBerry") != -1,
  Android: navigator.userAgent.indexOf('Android') != -1,
  MacOSX: navigator.userAgent.indexOf('Mac OS X') != -1 &&
    !Monocle.Browser.is.MobileSafari,
  Kindle3: !!navigator.userAgent.match(/Kindle\/3/)
  // TODO: Mac, Windows, etc
}


// It is only because MobileSafari is responsible for so much anguish that
// we special-case it here. Not a badge of honour.
//
if (Monocle.Browser.is.MobileSafari) {
  (function () {
    var ver = navigator.userAgent.match(/ OS ([\d_]+)/);
    if (ver) {
      Monocle.Browser.iOSVersion = ver[1].replace(/_/g, '.');
    } else {
      console.warn("Unknown MobileSafari user agent: "+navigator.userAgent);
    }
  })();
}
Monocle.Browser.iOSVersionBelow = function (strOrNum) {
  return !!Monocle.Browser.iOSVersion && Monocle.Browser.iOSVersion < strOrNum;
}


// A helper class for sniffing CSS features and creating CSS rules
// appropriate to the current rendering engine.
//
Monocle.Browser.css = new Monocle.CSS();


// During Reader initialization, this method is called to create the
// "environment", which tests for the existence of various browser
// features and bugs, then invokes the callback to continue initialization.
//
// If the survey has already been conducted and the env exists, calls
// callback immediately.
//
Monocle.Browser.survey = function (callback) {
  if (!Monocle.Browser.env) {
    Monocle.Browser.env = new Monocle.Env();
    Monocle.Browser.env.survey(callback);
  } else if (typeof callback == "function") {
    callback();
  }
}

Monocle.pieceLoaded('compat/browser');
Monocle.Factory = function (element, label, index, reader) {

  var API = { constructor: Monocle.Factory };
  var k = API.constants = API.constructor;
  var p = API.properties = {
    element: element,
    label: label,
    index: index,
    reader: reader,
    prefix: reader.properties.classPrefix || ''
  }


  // If index is null, uses the first available slot. If index is not null and
  // the slot is not free, throws an error.
  //
  function initialize() {
    if (!p.label) { return; }
    // Append the element to the reader's graph of DOM elements.
    var node = p.reader.properties.graph;
    node[p.label] = node[p.label] || [];
    if (typeof p.index == 'undefined' && node[p.label][p.index]) {
      throw('Element already exists in graph: '+p.label+'['+p.index+']');
    } else {
      p.index = p.index || node[p.label].length;
    }
    node[p.label][p.index] = p.element;

    // Add the label as a class name.
    addClass(p.label);
  }


  // Finds an element that has been created in the context of the current
  // reader, with the given label. If oIndex is not provided, returns first.
  // If oIndex is provided (eg, n), returns the nth element with the label.
  //
  function find(oLabel, oIndex) {
    if (!p.reader.properties.graph[oLabel]) {
      return null;
    }
    return p.reader.properties.graph[oLabel][oIndex || 0];
  }


  // Takes an elements and assimilates it into the reader -- essentially
  // giving it a "dom" object of it's own. It will then be accessible via find.
  //
  // Note that (as per comments for initialize), if oIndex is provided and
  // there is no free slot in the array for this label at that index, an
  // error will be thrown.
  //
  function claim(oElement, oLabel, oIndex) {
    return oElement.dom = new Monocle.Factory(
      oElement,
      oLabel,
      oIndex,
      p.reader
    );
  }


  // Create an element with the given label.
  //
  // The last argument (whether third or fourth) is the options hash. Your
  // options are:
  //
  //   class - the classname for the element. Must only be one name.
  //   html - the innerHTML for the element.
  //   text - the innerText for the element (an alternative to html, simpler).
  //
  // Returns the created element.
  //
  function make(tagName, oLabel, index_or_options, or_options) {
    var oIndex, options;
    if (arguments.length == 1) {
      oLabel = null,
      oIndex = 0;
      options = {};
    } else if (arguments.length == 2) {
      oIndex = 0;
      options = {};
    } else if (arguments.length == 4) {
      oIndex = arguments[2];
      options = arguments[3];
    } else if (arguments.length == 3) {
      var lastArg = arguments[arguments.length - 1];
      if (typeof lastArg == "number") {
        oIndex = lastArg;
        options = {};
      } else {
        oIndex = 0;
        options = lastArg;
      }
    }

    var oElement = document.createElement(tagName);
    claim(oElement, oLabel, oIndex);
    if (options['class']) {
      oElement.className += " "+p.prefix+options['class'];
    }
    if (options['html']) {
      oElement.innerHTML = options['html'];
    }
    if (options['text']) {
      oElement.appendChild(document.createTextNode(options['text']));
    }

    return oElement;
  }


  // Creates an element by passing all the given arguments to make. Then
  // appends the element as a child of the current element.
  //
  function append(tagName, oLabel, index_or_options, or_options) {
    var oElement = make.apply(this, arguments);
    p.element.appendChild(oElement);
    return oElement;
  }


  // Returns an array of [label, index, reader] for the given element.
  // A simple way to introspect the arguments required for #find, for eg.
  //
  function address() {
    return [p.label, p.index, p.reader];
  }


  // Apply a set of style rules (hash or string) to the current element.
  // See Monocle.Styles.applyRules for more info.
  //
  function setStyles(rules) {
    return Monocle.Styles.applyRules(p.element, rules);
  }


  function setBetaStyle(property, value) {
    return Monocle.Styles.affix(p.element, property, value);
  }


  // ClassName manipulation functions - with thanks to prototype.js!

  // Returns true if one of the current element's classnames matches name --
  // classPrefix aware (so don't concate the prefix onto it).
  //
  function hasClass(name) {
    name = p.prefix + name;
    var klass = p.element.className;
    if (!klass) { return false; }
    if (klass == name) { return true; }
    return new RegExp("(^|\\s)"+name+"(\\s|$)").test(klass);
  }


  // Adds name to the classnames of the current element (prepending the
  // reader's classPrefix first).
  //
  function addClass(name) {
    if (hasClass(name)) { return; }
    var gap = p.element.className ? ' ' : '';
    return p.element.className += gap+p.prefix+name;
  }


  // Removes (classPrefix+)name from the classnames of the current element.
  //
  function removeClass(name) {
    var reName = new RegExp("(^|\\s+)"+p.prefix+name+"(\\s+|$)");
    var reTrim = /^\s+|\s+$/g;
    var klass = p.element.className;
    p.element.className = klass.replace(reName, ' ').replace(reTrim, '');
    return p.element.className;
  }


  API.find = find;
  API.claim = claim;
  API.make = make;
  API.append = append;
  API.address = address;

  API.setStyles = setStyles;
  API.setBetaStyle = setBetaStyle;
  API.hasClass = hasClass;
  API.addClass = addClass;
  API.removeClass = removeClass;

  initialize();

  return API;
}

Monocle.pieceLoaded('core/factory');
Monocle.Events = {}


// Fire a custom event on a given target element. The attached data object will
// be available to all listeners at evt.m.
//
// Internet Explorer does not permit custom events; we'll wait for a
// version of IE that supports the W3C model.
//
Monocle.Events.dispatch = function (elem, evtType, data, cancelable) {
  if (!document.createEvent) {
    return true;
  }
  var evt = document.createEvent("Events");
  evt.initEvent(evtType, false, cancelable || false);
  evt.m = data;
  try {
    return elem.dispatchEvent(evt);
  } catch(e) {
    console.warn("Failed to dispatch event: "+evtType);
    return false;
  }
}


// Register a function to be invoked when an event fires.
//
Monocle.Events.listen = function (elem, evtType, fn, useCapture) {
  if (typeof elem == "string") { elem = document.getElementById(elem); }
  return elem.addEventListener(evtType, fn, useCapture || false);
}


// De-register a function from an event.
//
Monocle.Events.deafen = function (elem, evtType, fn, useCapture) {
  if (elem.removeEventListener) {
    return elem.removeEventListener(evtType, fn, useCapture || false);
  } else if (elem.detachEvent) {
    try {
      return elem.detachEvent('on'+evtType, fn);
    } catch(e) {}
  }
}


// Register a series of functions to listen for the start, move, end
// events of a mouse or touch interaction.
//
// 'fns' argument is an object like:
//
//   {
//     'start': function () { ... },
//     'move': function () { ... },
//     'end': function () { ... },
//     'cancel': function () { ... }
//   }
//
// All of the functions in this object are optional.
//
// Each function is passed the event, with additional generic info about the
// cursor/touch position:
//
//    event.m.offsetX (& offsetY) -- relative to top-left of document
//    event.m.registrantX (& registrantY) -- relative to top-left of elem
//
// 'options' argument:
//
//   {
//     'useCapture': true/false
//   }
//
// Returns an object that can later be passed to Monocle.Events.deafenForContact
//
Monocle.Events.listenForContact = function (elem, fns, options) {
  var listeners = {};

  var cursorInfo = function (evt, ci) {
    evt.m = {
      pageX: ci.pageX,
      pageY: ci.pageY
    };

    var target = evt.target || evt.srcElement;
    while (target.nodeType != 1 && target.parentNode) {
      target = target.parentNode;
    }

    // The position of contact from the top left of the element
    // on which the event fired.
    var offset = offsetFor(evt, target);
    evt.m.offsetX = offset[0];
    evt.m.offsetY = offset[1];

    // The position of contact from the top left of the element
    // on which the event is registered.
    if (evt.currentTarget) {
      offset = offsetFor(evt, evt.currentTarget);
      evt.m.registrantX = offset[0];
      evt.m.registrantY = offset[1];
    }

    return evt;
  }


  var offsetFor = function (evt, elem) {
    var r;
    if (elem.getBoundingClientRect) {
      var er = elem.getBoundingClientRect();
      var dr = document.documentElement.getBoundingClientRect();
      r = { left: er.left - dr.left, top: er.top - dr.top };
    } else {
      r = { left: elem.offsetLeft, top: elem.offsetTop }
      while (elem = elem.offsetParent) {
        if (elem.offsetLeft || elem.offsetTop) {
          r.left += elem.offsetLeft;
          r.top += elem.offsetTop;
        }
      }
    }
    return [evt.m.pageX - r.left, evt.m.pageY - r.top];
  }


  var capture = (options && options.useCapture) || false;

  if (!Monocle.Browser.env.touch) {
    if (fns.start) {
      listeners.mousedown = function (evt) {
        if (evt.button != 0) { return; }
        fns.start(cursorInfo(evt, evt));
      }
      Monocle.Events.listen(elem, 'mousedown', listeners.mousedown, capture);
    }
    if (fns.move) {
      listeners.mousemove = function (evt) {
        fns.move(cursorInfo(evt, evt));
      }
      Monocle.Events.listen(elem, 'mousemove', listeners.mousemove, capture);
    }
    if (fns.end) {
      listeners.mouseup = function (evt) {
        fns.end(cursorInfo(evt, evt));
      }
      Monocle.Events.listen(elem, 'mouseup', listeners.mouseup, capture);
    }
    if (fns.cancel) {
      listeners.mouseout = function (evt) {
        obj = evt.relatedTarget || evt.fromElement;
        while (obj && (obj = obj.parentNode)) {
          if (obj == elem) { return; }
        }
        fns.cancel(cursorInfo(evt, evt));
      }
      Monocle.Events.listen(elem, 'mouseout', listeners.mouseout, capture);
    }
  } else {
    if (fns.start) {
      listeners.start = function (evt) {
        if (evt.touches.length > 1) { return; }
        fns.start(cursorInfo(evt, evt.targetTouches[0]));
      }
    }
    if (fns.move) {
      listeners.move = function (evt) {
        if (evt.touches.length > 1) { return; }
        fns.move(cursorInfo(evt, evt.targetTouches[0]));
      }
    }
    if (fns.end) {
      listeners.end = function (evt) {
        fns.end(cursorInfo(evt, evt.changedTouches[0]));
        // BROWSERHACK:
        // If there is something listening for contact end events, we always
        // prevent the default, because TouchMonitor can't do it (since it
        // fires it on a delay: ugh). Would be nice to remove this line and
        // standardise things.
        evt.preventDefault();
      }
    }
    if (fns.cancel) {
      listeners.cancel = function (evt) {
        fns.cancel(cursorInfo(evt, evt.changedTouches[0]));
      }
    }

    if (Monocle.Browser.env.brokenIframeTouchModel) {
      Monocle.Events.tMonitor = Monocle.Events.tMonitor ||
        new Monocle.Events.TouchMonitor();
      Monocle.Events.tMonitor.listen(elem, listeners, options);
    } else {
      for (etype in listeners) {
        Monocle.Events.listen(elem, 'touch'+etype, listeners[etype], capture);
      }
    }
  }

  return listeners;
}


// The 'listeners' argument is a hash of event names and the functions that
// are registered to them -- de-registers the functions from the events.
//
Monocle.Events.deafenForContact = function (elem, listeners) {
  var prefix = "";
  if (Monocle.Browser.env.touch) {
    prefix = Monocle.Browser.env.brokenIframeTouchModel ? "contact" : "touch";
  }

  for (evtType in listeners) {
    Monocle.Events.deafen(elem, prefix + evtType, listeners[evtType]);
  }
}


// Looks for start/end events on an element without significant move events in
// between. Fires on the end event.
//
// Also sets up a dummy click event on Kindle3, so that the elem becomes a
// cursor target.
//
// If the optional activeClass string is provided, and if the element was
// created by a Monocle.Factory, then the activeClass will be applied to the
// element while it is being tapped.
//
// Returns a listeners object that you should pass to deafenForTap if you
// need to.
Monocle.Events.listenForTap = function (elem, fn, activeClass) {
  var startPos;

  // On Kindle, register a noop function with click to make the elem a
  // cursor target.
  if (Monocle.Browser.on.Kindle3) {
    Monocle.Events.listen(elem, 'click', function () {});
  }

  var annul = function () {
    startPos = null;
    if (activeClass && elem.dom) { elem.dom.removeClass(activeClass); }
  }

  var annulIfOutOfBounds = function (evt) {
    // We don't have to track this nonsense for mouse events.
    if (evt.type.match(/^mouse/)) {
      return;
    }
    // Doesn't work on iOS 3.1 for some reason, so ignore for that version.
    if (Monocle.Browser.is.MobileSafari && Monocle.Browser.iOSVersion < "3.2") {
      return;
    }
    if (
      evt.m.registrantX < 0 || evt.m.registrantX > elem.offsetWidth ||
      evt.m.registrantY < 0 || evt.m.registrantY > elem.offsetHeight
    ) {
      annul();
    }
  }

  return Monocle.Events.listenForContact(
    elem,
    {
      start: function (evt) {
        startPos = [evt.m.pageX, evt.m.pageY];
        if (activeClass && elem.dom) { elem.dom.addClass(activeClass); }
      },
      move: annulIfOutOfBounds,
      end: function (evt) {
        annulIfOutOfBounds(evt);
        if (startPos) {
          evt.m.startOffset = startPos;
          fn(evt);
        }
        annul();
      },
      cancel: annul
    },
    {
      useCapture: false
    }
  );
}


Monocle.Events.deafenForTap = Monocle.Events.deafenForContact;


// Listen for the next transition-end event on the given element, call
// the function, then deafen.
//
// Returns a function that can be used to cancel the listen early.
//
Monocle.Events.afterTransition = function (elem, fn) {
  var evtName = "transitionend";
  if (Monocle.Browser.is.WebKit) {
    evtName = 'webkitTransitionEnd';
  } else if (Monocle.Browser.is.Opera) {
    evtName =  'oTransitionEnd';
  }
  var l = null, cancel = null;
  l = function () { fn(); cancel(); }
  cancel = function () { Monocle.Events.deafen(elem, evtName, l); }
  Monocle.Events.listen(elem, evtName, l);
  return cancel;
}



// BROWSERHACK: iOS touch events on iframes are busted. The TouchMonitor,
// transposes touch events on underlying iframes onto the elements that
// sit above them. It's a massive hack.
Monocle.Events.TouchMonitor = function () {
  if (Monocle.Events == this) {
    return new Monocle.Events.TouchMonitor();
  }

  var API = { constructor: Monocle.Events.TouchMonitor }
  var k = API.constants = API.constructor;
  var p = API.properties = {
    touching: null,
    edataPrev: null,
    originator: null,
    brokenModel_4_1: navigator.userAgent.match(/ OS 4_1/)
  }


  function listenOnIframe(iframe) {
    if (iframe.contentDocument) {
      enableTouchProxy(iframe.contentDocument);
      iframe.contentDocument.isTouchFrame = true;
    }

    // IN 4.1 ONLY, a touchstart/end/both fires on the *frame* itself when a
    // touch completes on a part of the iframe that is not overlapped by
    // anything. This should be translated to a touchend on the touching
    // object.
    if (p.brokenModel_4_1) {
      enableTouchProxy(iframe);
    }
  }


  function listen(element, fns, useCapture) {
    for (etype in fns) {
      Monocle.Events.listen(element, 'contact'+etype, fns[etype], useCapture);
    }
    enableTouchProxy(element, useCapture);
  }


  function enableTouchProxy(element, useCapture) {
    if (element.monocleTouchProxy) {
      return;
    }
    element.monocleTouchProxy = true;

    var fn = function (evt) { touchProxyHandler(element, evt) }
    Monocle.Events.listen(element, "touchstart", fn, useCapture);
    Monocle.Events.listen(element, "touchmove", fn, useCapture);
    Monocle.Events.listen(element, "touchend", fn, useCapture);
    Monocle.Events.listen(element, "touchcancel", fn, useCapture);
  }


  function touchProxyHandler(element, evt) {
    var edata = {
      start: evt.type == "touchstart",
      move: evt.type == "touchmove",
      end: evt.type == "touchend" || evt.type == "touchcancel",
      time: new Date().getTime(),
      frame: element.isTouchFrame
    }

    if (!p.touching) {
      p.originator = element;
    }

    var target = element;
    var touch = evt.touches[0] || evt.changedTouches[0];
    target = document.elementFromPoint(touch.screenX, touch.screenY);

    if (target) {
      translateTouchEvent(element, target, evt, edata);
    }
  }


  function translateTouchEvent(element, target, evt, edata) {
    // IN 4.1 ONLY, if we have a touch start on the layer, and it's been
    // almost no time since we had a touch end on the layer, discard the start.
    // (This is the most broken thing about 4.1.)
    // FIXME: this seems to discard all "taps" on a naked iframe.
    if (
      p.brokenModel_4_1 &&
      !edata.frame &&
      !p.touching &&
      edata.start &&
      p.edataPrev &&
      p.edataPrev.end &&
      (edata.time - p.edataPrev.time) < 30
    ) {
      evt.preventDefault();
      return;
    }

    // If we don't have a touch and we see a start or a move on anything, start
    // a touch.
    if (!p.touching && !edata.end) {
      return fireStart(evt, target, edata);
    }

    // If this is a move event and we already have a touch, continue the move.
    if (edata.move && p.touching) {
      return fireMove(evt, edata);
    }

    if (p.brokenModel_4_1) {
      // IN 4.1 ONLY, if we have a touch in progress, and we see a start, end
      // or cancel event (moves are covered in previous rule), and the event
      // is not on the iframe, end the touch.
      // (This is because 4.1 bizarrely sends a random event to the layer
      // above the iframe, rather than an end event to the iframe itself.)
      if (p.touching && !edata.frame) {
        // However, a touch start will fire on the layer when moving out of
        // the overlap with the frame. This would trigger the end of the touch.
        // And the immediately subsequent move starts a new touch.
        //
        // To get around this, we only provisionally end the touch - if we get
        // a touchmove momentarily, we'll cancel this touchend.
        return fireProvisionalEnd(evt, edata);
      }
    } else {
      // In older versions of MobileSafari, if the touch ends when we're
      // touching something, just fire it.
      if (edata.end && p.touching) {
        return fireProvisionalEnd(evt, edata);
      }
    }

    // IN 4.1 ONLY, a touch that has started outside an iframe should not be
    // endable by the iframe.
    if (
      p.brokenModel_4_1 &&
      p.originator != element &&
      edata.frame &&
      edata.end
    ) {
      evt.preventDefault();
      return;
    }

    // If we see a touch end on the frame, end the touch.
    if (edata.frame && edata.end && p.touching) {
      return fireProvisionalEnd(evt, edata);
    }
  }


  function fireStart(evt, target, edata) {
    p.touching = target;
    p.edataPrev = edata;
    return fireTouchEvent(p.touching, 'start', evt);
  }


  function fireMove(evt, edata) {
    clearProvisionalEnd();
    p.edataPrev = edata;
    return fireTouchEvent(p.touching, 'move', evt);
  }


  function fireEnd(evt, edata) {
    var result = fireTouchEvent(p.touching, 'end', evt);
    p.edataPrev = edata;
    p.touching = null;
    return result;
  }


  function fireProvisionalEnd(evt, edata) {
    clearProvisionalEnd();
    var mimicEvt = mimicTouchEvent(p.touching, 'end', evt);
    p.edataPrev = edata;

    p.provisionalEnd = setTimeout(
      function() {
        if (p.touching) {
          p.touching.dispatchEvent(mimicEvt);
          p.touching = null;
        }
      },
      30
    );
  }


  function clearProvisionalEnd() {
    if (p.provisionalEnd) {
      clearTimeout(p.provisionalEnd);
      p.provisionalEnd = null;
    }
  }


  function mimicTouchEvent(target, newtype, evt) {
    var cloneTouch = function (t) {
      return document.createTouch(
        document.defaultView,
        target,
        t.identifier,
        t.screenX,
        t.screenY,
        t.screenX,
        t.screenY
      );
    }

    var findTouch = function (id) {
      for (var i = 0; i < touches.all.length; ++i) {
        if (touches.all[i].identifier == id) {
          return touches.all[i];
        }
      }
    }

    // Mimic the event data, dispatching it on the new target.
    var touches = { all: [], target: [], changed: [] };
    for (var i = 0; i < evt.touches.length; ++i) {
      touches.all.push(cloneTouch(evt.touches[i]));
    }
    for (var i = 0; i < evt.targetTouches.length; ++i) {
      touches.target.push(
        findTouch(evt.targetTouches[i].identifier) ||
        cloneTouch(evt.targetTouches[i])
      );
    }
    for (var i = 0; i < evt.changedTouches.length; ++i) {
      touches.changed.push(
        findTouch(evt.changedTouches[i].identifier) ||
        cloneTouch(evt.changedTouches[i])
      );
    }

    var mimicEvt = document.createEvent('TouchEvent');
    mimicEvt.initTouchEvent(
      "contact"+newtype,
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
      document.createTouchList.apply(document, touches.all),
      document.createTouchList.apply(document, touches.target),
      document.createTouchList.apply(document, touches.changed),
      evt.scale,
      evt.rotation
    );

    return mimicEvt;
  }


  function fireTouchEvent(target, newtype, evt) {
    var mimicEvt = mimicTouchEvent(target, newtype, evt);
    var result = target.dispatchEvent(mimicEvt);
    if (!result) {
      evt.preventDefault();
    }
    return result;
  }


  API.listen = listen;
  API.listenOnIframe = listenOnIframe;

  return API;
}


Monocle.Events.listenOnIframe = function (frame) {
  if (!Monocle.Browser.env.brokenIframeTouchModel) {
    return;
  }
  Monocle.Events.tMonitor = Monocle.Events.tMonitor ||
    new Monocle.Events.TouchMonitor();
  Monocle.Events.tMonitor.listenOnIframe(frame);
}

Monocle.pieceLoaded('core/events');
Monocle.Styles = {

  // Takes a hash and returns a string.
  rulesToString: function (rules) {
    if (typeof rules != 'string') {
      var parts = [];
      for (var declaration in rules) {
        parts.push(declaration+": "+rules[declaration]+";")
      }
      rules = parts.join(" ");
    }
    return rules;
  },


  // Takes a hash or string of CSS property assignments and applies them
  // to the element.
  //
  applyRules: function (elem, rules) {
    rules = Monocle.Styles.rulesToString(rules);
    elem.style.cssText += ';'+rules;
    return elem.style.cssText;
  },


  // Generates cross-browser properties for a given property.
  // ie, affix(<elem>, 'transition', 'linear 100ms') would apply that value
  // to webkitTransition for WebKit browsers, and to MozTransition for Gecko.
  //
  affix: function (elem, property, value) {
    var target = elem.style ? elem.style : elem;
    var props = Monocle.Browser.css.toDOMProps(property);
    while (props.length) { target[props.shift()] = value; }
  },


  setX: function (elem, x) {
    var s = elem.style;
    if (typeof x == "number") { x += "px"; }
    if (Monocle.Browser.env.supportsTransform3d) {
      s.webkitTransform = "translate3d("+x+", 0, 0)";
    } else {
      s.webkitTransform = "translateX("+x+")";
    }
    s.MozTransform = s.OTransform = s.transform = "translateX("+x+")";
    return x;
  },


  setY: function (elem, y) {
    var s = elem.style;
    if (typeof y == "number") { y += "px"; }
    if (Monocle.Browser.env.supportsTransform3d) {
      s.webkitTransform = "translate3d(0, "+y+", 0)";
    } else {
      s.webkitTransform = "translateY("+y+")";
    }
    s.MozTransform = s.OTransform = s.transform = "translateY("+y+")";
    return y;
  },


  getX: function (elem) {
    var currStyle = document.defaultView.getComputedStyle(elem, null);
    var re = /matrix\([^,]+,[^,]+,[^,]+,[^,]+,\s*([^,]+),[^\)]+\)/;
    var props = Monocle.Browser.css.toDOMProps('transform');
    var matrix = null;
    while (props.length && !matrix) {
      matrix = currStyle[props.shift()];
    }
    return parseInt(matrix.match(re)[1]);
  },


  transitionFor: function (elem, prop, duration, timing, delay) {
    var tProps = Monocle.Browser.css.toDOMProps('transition');
    var pProps = Monocle.Browser.css.toCSSProps(prop);
    timing = timing || "linear";
    delay = (delay || 0)+"ms";
    for (var i = 0, ii = tProps.length; i < ii; ++i) {
      var t = "none";
      if (duration) {
        t = [pProps[i], duration+"ms", timing, delay].join(" ");
      }
      elem.style[tProps[i]] = t;
    }
  }

}


// These rule definitions are more or less compulsory for Monocle to behave
// as expected. Which is why they appear here and not in the stylesheet.
// Adjust them if you know what you're doing.
//
Monocle.Styles.container = {
  "position": "absolute",
  "top": "0",
  "left": "0",
  "bottom": "0",
  "right": "0"
}

Monocle.Styles.page = {
  "position": "absolute",
  "z-index": "1",
  "-webkit-user-select": "none",
  "-moz-user-select": "none",
  "user-select": "none",
  "-webkit-transform": "translate3d(0,0,0)",
  "visibility": "visible"

  /*
  "background": "white",
  "top": "0",
  "left": "0",
  "bottom": "0",
  "right": "0"
  */
}

Monocle.Styles.sheaf = {
  "position": "absolute",
  "overflow": "hidden"

  /*
  "top": "0",
  "left": "0",
  "bottom": "0",
  "right": "0"
  */
}

Monocle.Styles.component = {
  "width": "100%",
  "height": "100%",
  //"border": "none",
  "-webkit-user-select": "none",
  "-moz-user-select": "none",
  "user-select": "none"
}

Monocle.Styles.control = {
  "z-index": "100",
  "cursor": "pointer"
}

Monocle.Styles.overlay = {
  "position": "absolute",
  "display": "none",
  "width": "100%",
  "height": "100%",
  "z-index": "1000"
}



Monocle.pieceLoaded('core/styles');
// READER
//
//
// The full DOM hierarchy created by Reader is:
//
//   box
//    -> container
//      -> pages (the number of page elements is determined by the flipper)
//        -> sheaf (basically just sets the margins)
//          -> component (an iframe created by the current component)
//            -> body (the document.body of the iframe)
//        -> page controls
//      -> standard controls
//    -> overlay
//      -> modal/popover controls
//
//
// Options:
//
//  flipper: The class of page flipper to use.
//
//  panels: The class of panels to use
//
//  stylesheet: A string of CSS rules to apply to the contents of each
//    component loaded into the reader.
//
//  place: A book locus for the page to open to when the reader is
//    initialized. (See comments at Book#pageNumberAt for more about
//    the locus option).
//
//  systemId: the id for root elements of components, defaults to "RS:monocle"
//
Monocle.Reader = function (node, bookData, options, onLoadCallback) {
  if (Monocle == this) {
    return new Monocle.Reader(node, bookData, options, onLoadCallback);
  }

  var API = { constructor: Monocle.Reader }
  var k = API.constants = API.constructor;
  var p = API.properties = {
    // Initialization-completed flag.
    initialized: false,

    // The active book.
    book: null,

    // DOM graph of factory-generated objects.
    graph: {},

    // An array of style rules that are automatically applied to every page.
    pageStylesheets: [],

    // Id applied to the HTML element of each component, can be used to scope
    // CSS rules.
    systemId: (options ? options.systemId : null) || k.DEFAULT_SYSTEM_ID,

    // Prefix for classnames for any created element.
    classPrefix: k.DEFAULT_CLASS_PREFIX,

    // Registered control objects (see addControl). Hashes of the form:
    //   {
    //     control: <control instance>,
    //     elements: <array of topmost elements created by control>,
    //     controlType: <standard, page, modal, popover, invisible, etc>
    //   }
    controls: [],

    // After the reader has been resized, this resettable timer must expire
    // the place is restored.
    resizeTimer: null,

    // Read the book from right to left
    rtl: false
  }

  var dom;


  // Inspects the browser environment and kicks off preparing the container.
  //
  function initialize() {
    options = options || {}

    if (options.rtl) p.rtl = options.rtl;

    Monocle.Browser.survey(prepareBox);
  }


  // Sets up the container and internal elements.
  //
  function prepareBox() {
    var box = node;
    if (typeof box == "string") { box = document.getElementById(box); }
    dom = API.dom = box.dom = new Monocle.Factory(box, 'box', 0, API);

    if (!Monocle.Browser.env.isCompatible()) {
      if (dispatchEvent("monocle:incompatible", {}, true)) {
        // TODO: Something cheerier? More informative?
        box.innerHTML = "Your browser is not compatible with Monocle.";
      }
      return;
    }

    dispatchEvent("monocle:initializing");

    var bk;
    if (bookData) {
      bk = new Monocle.Book(bookData);
    } else {
      bk = Monocle.Book.fromNodes([box.cloneNode(true)]);
    }
    box.innerHTML = "";

    // Make sure the box div is absolutely or relatively positioned.
    positionBox();

    // Attach the page-flipping gadget.
    attachFlipper(options.flipper);

    // Create the essential DOM elements.
    createReaderElements();

    // Clamp page frames to a set of styles that reduce Monocle breakage.
    clampStylesheets(options.stylesheet);

    primeFrames(options.primeURL, function () {
      // Make the reader elements look pretty.
      applyStyles();

      listen('monocle:componentmodify', persistPageStylesOnComponentChange);

      p.flipper.listenForInteraction(options.panels);

      setBook(bk, options.place, function () {
        p.initialized = true;
        if (onLoadCallback) { onLoadCallback(API); }
        dispatchEvent("monocle:loaded");
      });
    });
  }


  function positionBox() {
    var currPosVal;
    var box = dom.find('box');
    if (document.defaultView) {
      var currStyle = document.defaultView.getComputedStyle(box, null);
      currPosVal = currStyle.getPropertyValue('position');
    } else if (box.currentStyle) {
      currPosVal = box.currentStyle.position
    }
    if (["absolute", "relative"].indexOf(currPosVal) == -1) {
      box.style.position = "relative";
    }
  }


  function attachFlipper(flipperClass) {
    if (!flipperClass) {
      if (!Monocle.Browser.env.supportsColumns) {
        flipperClass = Monocle.Flippers.Legacy;
      } else if (Monocle.Browser.on.Kindle3) {
        flipperClass = Monocle.Flippers.Instant;
      }

      flipperClass = flipperClass || Monocle.Flippers.Slider;
    }

    if (!flipperClass) { throw("Flipper not found."); }

    p.flipper = new flipperClass(API, null, p.readerOptions);
  }


  function createReaderElements() {
    var cntr = dom.append('div', 'container');
    for (var i = 0; i < p.flipper.pageCount; ++i) {
      var page = cntr.dom.append('div', 'page', i);
      page.style.visibility = "hidden";
      page.m = { reader: API, pageIndex: i, place: null }
      page.m.sheafDiv = page.dom.append('div', 'sheaf', i);
      page.m.activeFrame = page.m.sheafDiv.dom.append('iframe', 'component', i);
      page.m.activeFrame.m = { 'pageDiv': page };
      page.m.activeFrame.setAttribute('frameBorder', 0);
      page.m.activeFrame.setAttribute('scrolling', 'no');
      p.flipper.addPage(page);
      // BROWSERHACK: hook up the iframe to the touchmonitor if it exists.
      Monocle.Events.listenOnIframe(page.m.activeFrame);
    }
    dom.append('div', 'overlay');
    dispatchEvent("monocle:loading");
  }


  function clampStylesheets(customStylesheet) {
    var defCSS = k.DEFAULT_STYLE_RULES;
    if (Monocle.Browser.env.floatsIgnoreColumns) {
      defCSS.push("html#RS\\:monocle * { float: none !important; }");
    }
    p.defaultStyles = addPageStyles(defCSS, false);
    if (customStylesheet) {
      p.initialStyles = addPageStyles(customStylesheet, false);
    }
  }


  // Opens the frame to a particular URL (usually 'about:blank').
  //
  function primeFrames(url, callback) {
    url = url || (Monocle.Browser.on.UIWebView ? "blank.html" : "about:blank");

    var pageCount = 0;

    var cb = function (evt) {
      var frame = evt.target || evt.srcElement;
      Monocle.Events.deafen(frame, 'load', cb);
      dispatchEvent(
        'monocle:frameprimed',
        { frame: frame, pageIndex: pageCount }
      );
      if ((pageCount += 1) == p.flipper.pageCount) {
        Monocle.defer(callback);
      }
    }

    forEachPage(function (page) {
      Monocle.Events.listen(page.m.activeFrame, 'load', cb);
      page.m.activeFrame.src = url;
    });
  }


  function applyStyles() {
    dom.find('container').dom.setStyles(Monocle.Styles.container);
    forEachPage(function (page, i) {
      page.dom.setStyles(Monocle.Styles.page);
      dom.find('sheaf', i).dom.setStyles(Monocle.Styles.sheaf);
      var cmpt = dom.find('component', i)
      cmpt.dom.setStyles(Monocle.Styles.component);
    });
    lockFrameWidths();
    dom.find('overlay').dom.setStyles(Monocle.Styles.overlay);
    dispatchEvent('monocle:styles');
  }


  function lockingFrameWidths() {
    if (!Monocle.Browser.env.relativeIframeExpands) { return; }
    for (var i = 0, cmpt; cmpt = dom.find('component', i); ++i) {
      cmpt.style.display = "none";
    }
  }


  function lockFrameWidths() {
    if (!Monocle.Browser.env.relativeIframeExpands) { return; }
    for (var i = 0, cmpt; cmpt = dom.find('component', i); ++i) {
      cmpt.style.width = cmpt.parentNode.offsetWidth+"px";
      cmpt.style.display = "inline-block";
    }
  }


  // Apply the book, move to a particular place or just the first page, wait
  // for everything to complete, then fire the callback.
  //
  function setBook(bk, place, callback) {
    p.book = bk;
    var pageCount = 0;
    if (typeof callback == 'function') {
      var watchers = {
        'monocle:componentchange': function (evt) {
          dispatchEvent('monocle:firstcomponentchange', evt.m);
          return (pageCount += 1) == p.flipper.pageCount;
        },
        'monocle:turn': function (evt) {
          callback();
          return true;
        }
      }
      var listener = function (evt) {
        if (watchers[evt.type](evt)) { deafen(evt.type, listener); }
      }
      for (evtType in watchers) { listen(evtType, listener) }
    }
    p.flipper.moveTo(place || { page: 1 });
  }


  function getBook() {
    return p.book;
  }


  // Attempts to restore the place we were up to in the book before the
  // reader was resized.
  //
  function resized() {
    if (!p.initialized) {
      console.warn('Attempt to resize book before initialization.');
    }
    lockingFrameWidths();
    if (!dispatchEvent("monocle:resizing", {}, true)) {
      return;
    }
    clearTimeout(p.resizeTimer);
    p.resizeTimer = setTimeout(
      function () {
        lockFrameWidths();
        recalculateDimensions(true);
        dispatchEvent("monocle:resize");
      },
      k.RESIZE_DELAY
    );
  }


  function recalculateDimensions(andRestorePlace) {
    if (!p.book) { return; }
    dispatchEvent("monocle:recalculating");

    var place, locus;
    if (andRestorePlace !== false) {
      var place = getPlace();
      var locus = { percent: place ? place.percentageThrough() : 0 };
    }

    // Better to use an event? Or chaining consecutively?
    forEachPage(function (pageDiv) {
      pageDiv.m.activeFrame.m.component.updateDimensions(pageDiv);
    });

    Monocle.defer(function () {
      if (locus) { p.flipper.moveTo(locus); }
      dispatchEvent("monocle:recalculated");
    });
  }


  // Returns the current page number in the book.
  //
  // The pageDiv argument is optional - typically defaults to whatever the
  // flipper thinks is the "active" page.
  //
  function pageNumber(pageDiv) {
    var place = getPlace(pageDiv);
    return place ? (place.pageNumber() || 1) : 1;
  }


  // Returns the current "place" in the book -- ie, the page number, chapter
  // title, etc.
  //
  // The pageDiv argument is optional - typically defaults to whatever the
  // flipper thinks is the "active" page.
  //
  function getPlace(pageDiv) {
    if (!p.initialized) {
      console.warn('Attempt to access place before initialization.');
    }
    return p.flipper.getPlace(pageDiv);
  }


  // Moves the current page as specified by the locus. See
  // Monocle.Book#pageNumberAt for documentation on the locus argument.
  //
  // The callback argument is optional.
  //
  function moveTo(locus, callback) {
    if (!p.initialized) {
      console.warn('Attempt to move place before initialization.');
    }
    if (!p.book.isValidLocus(locus)) {
      dispatchEvent(
        "monocle:notfound",
        { href: locus ? locus.componentId : "anonymous" }
      );
      return false;
    }
    var fn = callback;
    if (!locus.direction) {
      dispatchEvent('monocle:jumping', { locus: locus });
      fn = function () {
        dispatchEvent('monocle:jump', { locus: locus });
        if (callback) { callback(); }
      }
    }
    p.flipper.moveTo(locus, fn);
    return true;
  }


  // Moves to the relevant element in the relevant component.
  //
  function skipToChapter(src) {
    var locus = p.book.locusOfChapter(src);
    return moveTo(locus);
  }


  // Valid types:
  //  - standard (an overlay above the pages)
  //  - page (within the page)
  //  - modal (overlay where click-away does nothing, for a single control)
  //  - hud (overlay that multiple controls can share)
  //  - popover (overlay where click-away removes the ctrl elements)
  //  - invisible
  //
  // Options:
  //  - hidden -- creates and hides the ctrl elements;
  //              use showControl to show them
  //
  function addControl(ctrl, cType, options) {
    for (var i = 0; i < p.controls.length; ++i) {
      if (p.controls[i].control == ctrl) {
        console.warn("Already added control: " + ctrl);
        return;
      }
    }

    options = options || {};

    var ctrlData = {
      control: ctrl,
      elements: [],
      controlType: cType
    }
    p.controls.push(ctrlData);

    var ctrlElem;
    var cntr = dom.find('container'), overlay = dom.find('overlay');
    if (!cType || cType == "standard") {
      ctrlElem = ctrl.createControlElements(cntr);
      cntr.appendChild(ctrlElem);
      ctrlData.elements.push(ctrlElem);
    } else if (cType == "page") {
      forEachPage(function (page, i) {
        var runner = ctrl.createControlElements(page);
        page.appendChild(runner);
        ctrlData.elements.push(runner);
      });
    } else if (cType == "modal" || cType == "popover" || cType == "hud") {
      ctrlElem = ctrl.createControlElements(overlay);
      overlay.appendChild(ctrlElem);
      ctrlData.elements.push(ctrlElem);
      ctrlData.usesOverlay = true;
    } else if (cType == "invisible") {
      if (
        typeof(ctrl.createControlElements) == "function" &&
        (ctrlElem = ctrl.createControlElements(cntr))
      ) {
        cntr.appendChild(ctrlElem);
        ctrlData.elements.push(ctrlElem);
      }
    } else {
      console.warn("Unknown control type: " + cType);
    }

    for (var i = 0; i < ctrlData.elements.length; ++i) {
      Monocle.Styles.applyRules(ctrlData.elements[i], Monocle.Styles.control);
    }

    if (options.hidden) {
      hideControl(ctrl);
    } else {
      showControl(ctrl);
    }

    if (typeof ctrl.assignToReader == 'function') {
      ctrl.assignToReader(API);
    }

    return ctrl;
  }


  function dataForControl(ctrl) {
    for (var i = 0; i < p.controls.length; ++i) {
      if (p.controls[i].control == ctrl) {
        return p.controls[i];
      }
    }
  }


  function hideControl(ctrl) {
    var controlData = dataForControl(ctrl);
    if (!controlData) {
      console.warn("No data for control: " + ctrl);
      return;
    }
    if (controlData.hidden) {
      return;
    }
    for (var i = 0; i < controlData.elements.length; ++i) {
      controlData.elements[i].style.display = "none";
    }
    if (controlData.usesOverlay) {
      var overlay = dom.find('overlay');
      overlay.style.display = "none";
      Monocle.Events.deafenForContact(overlay, overlay.listeners);
    }
    controlData.hidden = true;
    if (ctrl.properties) {
      ctrl.properties.hidden = true;
    }
    dispatchEvent('monocle:controlhide', { control: ctrl }, false);
  }


  function showControl(ctrl) {
    var controlData = dataForControl(ctrl);
    if (!controlData) {
      console.warn("No data for control: " + ctrl);
      return false;
    }

    if (showingControl(ctrl)) {
      return false;
    }

    var overlay = dom.find('overlay');
    if (controlData.usesOverlay && controlData.controlType != "hud") {
      for (var i = 0, ii = p.controls.length; i < ii; ++i) {
        if (p.controls[i].usesOverlay && !p.controls[i].hidden) {
          return false;
        }
      }
      overlay.style.display = "block";
    }

    for (var i = 0; i < controlData.elements.length; ++i) {
      controlData.elements[i].style.display = "block";
    }

    if (controlData.controlType == "popover") {
      var onControl = function (evt) {
        var obj = evt.target;
        do {
          if (obj == controlData.elements[0]) { return true; }
        } while (obj && (obj = obj.parentNode));
        return false;
      }
      overlay.listeners = Monocle.Events.listenForContact(
        overlay,
        {
          start: function (evt) { if (!onControl(evt)) { hideControl(ctrl); } },
          move: function (evt) { if (!onControl(evt)) { evt.preventDefault(); } }
        }
      );
    }
    controlData.hidden = false;
    if (ctrl.properties) {
      ctrl.properties.hidden = false;
    }
    dispatchEvent('monocle:controlshow', { control: ctrl }, false);
    return true;
  }


  function showingControl(ctrl) {
    var controlData = dataForControl(ctrl);
    return controlData.hidden == false;
  }


  function dispatchEvent(evtType, data, cancelable) {
    return Monocle.Events.dispatch(dom.find('box'), evtType, data, cancelable);
  }


  function listen(evtType, fn, useCapture) {
    Monocle.Events.listen(dom.find('box'), evtType, fn, useCapture);
  }


  function deafen(evtType, fn) {
    Monocle.Events.deafen(dom.find('box'), evtType, fn);
  }


  /* PAGE STYLESHEETS */

  // API for adding a new stylesheet to all components. styleRules should be
  // a string of CSS rules. restorePlace defaults to true.
  //
  // Returns a sheet index value that can be used with updatePageStyles
  // and removePageStyles.
  //
  function addPageStyles(styleRules, restorePlace) {
    return changingStylesheet(function () {
      p.pageStylesheets.push(styleRules);
      var sheetIndex = p.pageStylesheets.length - 1;

      for (var i = 0; i < p.flipper.pageCount; ++i) {
        var doc = dom.find('component', i).contentDocument;
        addPageStylesheet(doc, sheetIndex);
      }
      return sheetIndex;
    }, restorePlace);
  }


  // API for updating the styleRules in an existing page stylesheet across
  // all components. Takes a sheet index value obtained via addPageStyles.
  //
  function updatePageStyles(sheetIndex, styleRules, restorePlace) {
    return changingStylesheet(function () {
      p.pageStylesheets[sheetIndex] = styleRules;
      if (typeof styleRules.join == "function") {
        styleRules = styleRules.join("\n");
      }
      for (var i = 0; i < p.flipper.pageCount; ++i) {
        var doc = dom.find('component', i).contentDocument;
        var styleTag = doc.getElementById('monStylesheet'+sheetIndex);
        if (!styleTag) {
          console.warn('No such stylesheet: ' + sheetIndex);
          return;
        }
        if (styleTag.styleSheet) {
          styleTag.styleSheet.cssText = styleRules;
        } else {
          styleTag.replaceChild(
            doc.createTextNode(styleRules),
            styleTag.firstChild
          );
        }
      }
    }, restorePlace);
  }


  // API for removing a page stylesheet from all components. Takes a sheet
  // index value obtained via addPageStyles.
  //
  function removePageStyles(sheetIndex, restorePlace) {
    return changingStylesheet(function () {
      p.pageStylesheets[sheetIndex] = null;
      for (var i = 0; i < p.flipper.pageCount; ++i) {
        var doc = dom.find('component', i).contentDocument;
        var styleTag = doc.getElementById('monStylesheet'+sheetIndex);
        styleTag.parentNode.removeChild(styleTag);
      }
    }, restorePlace);
  }


  // Called when a page changes its component. Injects our current page
  // stylesheets into the new component.
  //
  function persistPageStylesOnComponentChange(evt) {
    var doc = evt.m['document'];
    doc.documentElement.id = p.systemId;
    for (var i = 0; i < p.pageStylesheets.length; ++i) {
      if (p.pageStylesheets[i]) {
        addPageStylesheet(doc, i);
      }
    }
  }


  // Wraps all API-based stylesheet changes (add, update, remove) in a
  // brace of custom events (stylesheetchanging/stylesheetchange), and
  // recalculates component dimensions if specified (default to true).
  //
  function changingStylesheet(callback, restorePlace) {
    restorePlace = (restorePlace === false) ? false : true;
    if (restorePlace) {
      dispatchEvent("monocle:stylesheetchanging", {});
    }
    var result = callback();
    if (restorePlace) {
      recalculateDimensions(true);
      Monocle.defer(
        function () { dispatchEvent("monocle:stylesheetchange", {}); }
      );
    } else {
      recalculateDimensions(false);
    }
    return result;
  }


  // Private method for adding a stylesheet to a component. Used by
  // addPageStyles.
  //
  function addPageStylesheet(doc, sheetIndex) {
    var styleRules = p.pageStylesheets[sheetIndex];

    if (!styleRules) {
      return;
    }

    var head = doc.getElementsByTagName('head')[0];
    if (!head) {
      head = doc.createElement('head');
      doc.documentElement.appendChild(head);
    }

    if (typeof styleRules.join == "function") {
      styleRules = styleRules.join("\n");
    }

    var styleTag = doc.createElement('style');
    styleTag.type = 'text/css';
    styleTag.id = "monStylesheet"+sheetIndex;
    if (styleTag.styleSheet) {
      styleTag.styleSheet.cssText = styleRules;
    } else {
      styleTag.appendChild(doc.createTextNode(styleRules));
    }

    head.appendChild(styleTag);

    return styleTag;
  }


  function visiblePages() {
    return p.flipper.visiblePages ? p.flipper.visiblePages() : [dom.find('page')];
  }


  function forEachPage(callback) {
    for (var i = 0, ii = p.flipper.pageCount; i < ii; ++i) {
      var page = dom.find('page', i);
      callback(page, i);
    }
  }


  API.getBook = getBook;
  API.getPlace = getPlace;
  API.moveTo = moveTo;
  API.skipToChapter = skipToChapter;
  API.resized = resized;
  API.addControl = addControl;
  API.hideControl = hideControl;
  API.showControl = showControl;
  API.showingControl = showingControl;
  API.dispatchEvent = dispatchEvent;
  API.listen = listen;
  API.deafen = deafen;
  API.addPageStyles = addPageStyles;
  API.updatePageStyles = updatePageStyles;
  API.removePageStyles = removePageStyles;
  API.visiblePages = visiblePages;

  initialize();

  return API;
}


Monocle.Reader.RESIZE_DELAY = 100;
Monocle.Reader.DEFAULT_SYSTEM_ID = 'RS:monocle'
Monocle.Reader.DEFAULT_CLASS_PREFIX = 'monelem_'
Monocle.Reader.DEFAULT_STYLE_RULES = [
  "html#RS\\:monocle * {" +
    "-webkit-font-smoothing: subpixel-antialiased;" +
    "text-rendering: auto !important;" +
    "word-wrap: break-word !important;" +
    "overflow: visible !important;" +
  "}",
  "html#RS\\:monocle body {" +
    "margin: 0 !important;"+
    "border: none !important;" +
    "padding: 0 !important;" +
    "width: 100% !important;" +
    "position: absolute !important;" +
    "-webkit-text-size-adjust: none;" +
  "}",
  "html#RS\\:monocle body * {" +
    "max-width: 100% !important;" +
  "}",
  "html#RS\\:monocle img {" +
    "max-height: 100% !important;" +
  "}",
  "html#RS\\:monocle video, html#RS\\:monocle object {" +
    "height: auto !important;" +
  "}"
]

Monocle.pieceLoaded('core/reader');
/* BOOK */

/* The Book handles movement through the content by the reader page elements.
 *
 * It's responsible for instantiating components as they are required,
 * and for calculating which component and page number to move to (based on
 * requests from the Reader).
 *
 * It should set and know the place of each page element too.
 *
 */

Monocle.Book = function (dataSource) {
  if (Monocle == this) { return new Monocle.Book(dataSource); }

  var API = { constructor: Monocle.Book }
  var k = API.constants = API.constructor;
  var p = API.properties = {
    dataSource: dataSource,
    components: [],
    chapters: {} // flat arrays of chapters per component
  }


  function initialize() {
    p.componentIds = dataSource.getComponents();
    p.contents = dataSource.getContents();
    p.lastCIndex = p.componentIds.length - 1;
  }


  // Adjusts the given locus object to provide the page number within the
  // current component.
  //
  // If the locus implies movement to another component, the locus
  // 'componentId' property will be updated to point to this component, and
  // the 'load' property will be set to true, which should be taken as a
  // sign to call loadPageAt with a callback.
  //
  // The locus argument is an object that has one of the following properties:
  //
  //  - page: positive integer. Counting up from the start of component.
  //  - pagesBack: negative integer. Counting back from the end of component.
  //  - percent: float
  //  - direction: integer relative to the current page number for this pageDiv
  //  - position: string, one of "start" or "end", moves to corresponding point
  //      in the given component
  //  - anchor: an element id within the component
  //  - xpath: the node at this XPath within the component
  //  - selector: the first node at this CSS selector within the component
  //
  // The locus object can also specify a componentId. If it is not provided
  // we default to the currently active component, and if that doesn't exist,
  // we default to the very first component.
  //
  // The locus result will be an object with the following properties:
  //
  //  - load: boolean, true if loading component required, false otherwise
  //  - componentId: component to load (current componentId if load is false)
  //  - if load is false:
  //    - page
  //  - if load is true:
  //    - one of page / pagesBack / percent / direction / position / anchor
  //
  //  And the epub3 fixed layout properties (only when load is false):
  //
  //  - layout: "reflowable" / "pre-paginated" / null
  //  - orientation: "landscape" / "portrait" / "auto" / null
  //  - spread: "none" / "landscape" / "portrait" / "both" / "auto" / null
  //  - pageSpread: "left" / "right" / "center" / null
  //  - dimensions: [width, height] / null
  //
  function pageNumberAt(pageDiv, locus) {
    locus.load = false;
    var currComponent = pageDiv.m.activeFrame ?
      pageDiv.m.activeFrame.m.component :
      null;
    var component = null;
    var cIndex = p.componentIds.indexOf(locus.componentId);
    if (cIndex < 0 && !currComponent) {
      // No specified component, no current component. Load first component.
      locus.load = true;
      locus.componentId = p.componentIds[0];
      return locus;
    } else if (
      cIndex < 0 &&
      locus.componentId &&
      currComponent.properties.id != locus.componentId
    ) {
      // Invalid component, say not found.
      pageDiv.m.reader.dispatchEvent(
        "monocle:notfound",
        { href: locus.componentId }
      );
      return null;
    } else if (cIndex < 0) {
      // No specified (or invalid) component, use current component.
      component = currComponent;
      locus.componentId = pageDiv.m.activeFrame.m.component.properties.id;
      cIndex = p.componentIds.indexOf(locus.componentId);
    } else if (!p.components[cIndex] || p.components[cIndex] != currComponent) {
      // Specified component differs from current component. Load specified.
      locus.load = true;
      return locus;
    } else {
      component = currComponent;
    }

    // If we're here, then the locus is based on the current component.
    var result = { load: false, componentId: locus.componentId, page: 1 }
    if (component.properties.layout) {
      result.layout = component.properties.layout;
    }
    if (component.properties.orientation) {
      result.orientation = component.properties.orientation;
    }
    if (component.properties.spread) {
      result.spread = component.properties.spread;
    }
    if (component.properties.pageSpread) {
      result.pageSpread = component.properties.pageSpread;
    }
    if (component.properties.dimensions) {
      result.dimensions = component.properties.dimensions;
    }

    // Get the current last page.
    lastPageNum = component.lastPageNumber();

    // Deduce the page number for the given locus.
    if (typeof(locus.page) == "number") {
      result.page = locus.page;
    } else if (typeof(locus.pagesBack) == "number") {
      result.page = lastPageNum + locus.pagesBack;
    } else if (typeof(locus.percent) == "number") {
      var place = new Monocle.Place();
      place.setPlace(component, 1);
      result.page = place.pageAtPercentageThrough(locus.percent);
    } else if (typeof(locus.direction) == "number") {
      if (!pageDiv.m.place) {
        console.warn("Can't move in a direction if pageDiv has no place.");
      }
      result.page = pageDiv.m.place.pageNumber();
      result.page += locus.direction;
    } else if (typeof(locus.anchor) == "string") {
      result.page = component.pageForChapter(locus.anchor, pageDiv);
    } else if (typeof(locus.xpath) == "string") {
      result.page = component.pageForXPath(locus.xpath, pageDiv);
    } else if (typeof(locus.selector) == "string") {
      result.page = component.pageForSelector(locus.selector, pageDiv);
    } else if (typeof(locus.position) == "string") {
      if (locus.position == "start") {
        result.page = 1;
      } else if (locus.position == "end") {
        result.page = lastPageNum['new'];
      }
    } else {
      console.warn("Unrecognised locus: " + locus);
      result.page = 1;
    }

    if (result.page < 1) {
      if (cIndex == 0) {
        // On first page of book.
        result.page = 1;
        result.boundarystart = true;
      } else {
        // Moving backwards from current component.
        result.load = true;
        result.componentId = p.componentIds[cIndex - 1];
        result.pagesBack = result.page;
        result.page = null;
        result.layout = null;
        result.orientation = null;
        result.spread = null;
        result.pageSpread = null;
        result.dimensions = null;
      }
    } else if (result.page > lastPageNum) {
      if (cIndex == p.lastCIndex) {
        // On last page of book.
        result.page = lastPageNum;
        result.boundaryend = true;
      } else {
        // Moving forwards from current component.
        result.load = true;
        result.componentId = p.componentIds[cIndex + 1];
        result.page -= lastPageNum;
        result.layout = null;
        result.orientation = null;
        result.spread = null;
        result.pageSpread = null;
        result.dimensions = null;
      }
    }

    return result;
  }


  // Same as pageNumberAt, but if a load is not flagged, this will
  // automatically update the pageDiv's place to the given pageNumber.
  //
  // If you call this (ie, from a flipper), you are effectively entering into
  // a contract to move the frame offset to the given page returned in the
  // locus if load is false.
  //
  function setPageAt(pageDiv, locus) {
    locus = pageNumberAt(pageDiv, locus);
    if (locus && !locus.load) {
      var evtData = { locus: locus, page: pageDiv }
      if (locus.boundarystart) {
        pageDiv.m.reader.dispatchEvent('monocle:boundarystart', evtData);
      } else if (locus.boundaryend) {
        pageDiv.m.reader.dispatchEvent('monocle:boundaryend', evtData);
      } else {
        var component = p.components[p.componentIds.indexOf(locus.componentId)];
        pageDiv.m.place = pageDiv.m.place || new Monocle.Place();
        pageDiv.m.place.setPlace(component, locus.page);

        var evtData = {
          page: pageDiv,
          locus: locus,
          pageNumber: pageDiv.m.place.pageNumber(),
          componentId: locus.componentId
        }
        pageDiv.m.reader.dispatchEvent("monocle:pagechange", evtData);
      }
    }
    return locus;
  }


  // Will load the given component into the pageDiv's frame, then invoke the
  // callback with resulting locus (provided by pageNumberAt).
  //
  // If the resulting page number is outside the bounds of the new component,
  // (ie, pageNumberAt again requests a load), this will recurse into further
  // components until non-loading locus is returned by pageNumberAt. Then the
  // callback will fire with that locus.
  //
  // As with setPageAt, if you call this you're obliged to move the frame
  // offset to the given page in the locus passed to the callback.
  //
  // If you pass a function as the progressCallback argument, the logic of this
  // function will be in your control. The function will be invoked between:
  //
  // a) loading the component and
  // b) applying the component to the frame and
  // c) loading any further components if required
  //
  // with a function argument that performs the next step in the process. So
  // if you need to do some special handling during the load process, you can.
  //
  function loadPageAt(pageDiv, locus, callback, progressCallback) {
    var cIndex = p.componentIds.indexOf(locus.componentId);
    if (!locus.load || cIndex < 0) {
      locus = pageNumberAt(pageDiv, locus);
    }

    if (!locus) {
      return;
    }

    if (!locus.load) {
      callback(locus);
      return;
    }

    var findPageNumber = function () {
      locus = setPageAt(pageDiv, locus);
      if (!locus) {
        return;
      } else if (locus.load) {
        loadPageAt(pageDiv, locus, callback, progressCallback)
      } else {
        callback(locus);
      }
    }

    var pgFindPageNumber = function () {
      progressCallback ? progressCallback(findPageNumber) : findPageNumber();
    }

    var applyComponent = function (component) {
      component.applyTo(pageDiv, pgFindPageNumber);
    }

    loadComponent(cIndex, applyComponent, pageDiv);
  }


  // If your flipper doesn't care whether a component needs to be
  // loaded before the page can be set, you can use this shortcut.
  //
  function setOrLoadPageAt(pageDiv, locus, callback, onProgress, onFail) {
    locus = setPageAt(pageDiv, locus);
    if (!locus) {
      if (onFail) { onFail(); }
    } else if (locus.load) {
      loadPageAt(pageDiv, locus, callback, onProgress);
    } else {
      callback(locus);
    }
  }


  // Fetches the component source from the dataSource.
  //
  // 'index' is the index of the component in the
  // dataSource.getComponents array.
  //
  // 'callback' is invoked when the source is received.
  //
  // 'pageDiv' is optional, and simply allows firing events on
  // the reader object that has requested this component, ONLY if
  // the source has not already been received.
  //
  function loadComponent(index, callback, pageDiv) {
    if (p.components[index]) {
      return callback(p.components[index]);
    }
    var cmptId = p.componentIds[index];
    if (pageDiv) {
      var evtData = { 'page': pageDiv, 'component': cmptId, 'index': index };
      pageDiv.m.reader.dispatchEvent('monocle:componentloading', evtData);
    }
    var failedToLoadComponent = function () {
      console.warn("Failed to load component: "+cmptId);
      pageDiv.m.reader.dispatchEvent('monocle:componentfailed', evtData);
      try {
        var currCmpt = pageDiv.m.activeFrame.m.component;
        evtData.cmptId = currCmpt.properties.id;
        callback(currCmpt);
      } catch (e) {
        console.warn("Failed to fall back to previous component.");
      }
    }

    var fn = function (cmptSource, options) {
      if (cmptSource === false) { return failedToLoadComponent(); }
      if (pageDiv) {
        evtData['source'] = cmptSource;
        pageDiv.m.reader.dispatchEvent('monocle:componentloaded', evtData);
        html = evtData['html'];
      }
      p.components[index] = new Monocle.Component(
        API,
        cmptId,
        index,
        chaptersForComponent(cmptId),
        cmptSource
      );
      if (options) {
        var props = p.components[index].properties;
        if (options.layout) {
          props.layout = options.layout;
        }
        if (options.orientation) {
          props.orientation = options.orientation;
        }
        if (options.spread) {
          props.spread = options.spread;
        }
        if (options.pageSpread) {
          props.pageSpread = options.pageSpread;
        }
        if (options.dimensions) {
          props.dimensions = options.dimensions;
        }
      }
      callback(p.components[index]);
    };
    var cmptSource = p.dataSource.getComponent(cmptId, fn);
    if (cmptSource && !p.components[index]) {
      fn(cmptSource);
    } else if (cmptSource === false) {
      return failedToLoadComponent();
    }
  }


  // Returns an array of chapter objects that are found in the given component.
  //
  // A chapter object has this format:
  //
  //    {
  //      title: "Chapter 1",
  //      fragment: null
  //    }
  //
  // The fragment property of a chapter object is either null (the chapter
  // starts at the head of the component) or the fragment part of the URL
  // (eg, "foo" in "index.html#foo").
  //
  function chaptersForComponent(cmptId) {
    if (p.chapters[cmptId]) {
      return p.chapters[cmptId];
    }
    p.chapters[cmptId] = [];
    var matcher = new RegExp('^'+cmptId+"(\#(.+)|$)");
    var matches;
    var recurser = function (chp) {
      if (matches = chp.src.match(matcher)) {
        p.chapters[cmptId].push({
          title: chp.title,
          fragment: matches[2] || null
        });
      }
      if (chp.children) {
        for (var i = 0; i < chp.children.length; ++i) {
          recurser(chp.children[i]);
        }
      }
    }

    for (var i = 0; i < p.contents.length; ++i) {
      recurser(p.contents[i]);
    }
    return p.chapters[cmptId];
  }


  // Returns a locus for the chapter that has the URL given in the
  // 'src' argument.
  //
  // See the comments at pageNumberAt for an explanation of locus objects.
  //
  function locusOfChapter(src) {
    var matcher = new RegExp('^(.+?)(#(.*))?$');
    var matches = src.match(matcher);
    if (!matches) { return null; }
    var cmptId = componentIdMatching(matches[1]);
    if (!cmptId) { return null; }
    var locus = { componentId: cmptId }
    matches[3] ? locus.anchor = matches[3] : locus.position = "start";
    return locus;
  }


  function isValidLocus(locus) {
    if (!locus) { return false; }
    if (locus.componentId && !componentIdMatching(locus.componentId)) {
      return false;
    }
    return true;
  }


  function componentIdMatching(str) {
    return p.componentIds.indexOf(str) >= 0 ? str : null;
  }


  API.getMetaData = dataSource.getMetaData;
  API.pageNumberAt = pageNumberAt;
  API.setPageAt = setPageAt;
  API.loadPageAt = loadPageAt;
  API.setOrLoadPageAt = setOrLoadPageAt;
  API.chaptersForComponent = chaptersForComponent;
  API.locusOfChapter = locusOfChapter;
  API.isValidLocus = isValidLocus;

  initialize();

  return API;
}


// A shortcut for creating a book from an array of nodes.
//
// You could use this as follows, for eg:
//
//  Monocle.Book.fromNodes([document.getElementById('content')]);
//
Monocle.Book.fromNodes = function (nodes) {
  var bookData = {
    getComponents: function () {
      return ['anonymous'];
    },
    getContents: function () {
      return [];
    },
    getComponent: function (n) {
      return { 'nodes': nodes };
    },
    getMetaData: function (key) {
    }
  }

  return new Monocle.Book(bookData);
}

Monocle.pieceLoaded('core/book');
// PLACE

Monocle.Place = function () {

  var API = { constructor: Monocle.Place }
  var k = API.constants = API.constructor;
  var p = API.properties = {
    component: null,
    percent: null
  }


  function setPlace(cmpt, pageN) {
    p.component = cmpt;
    p.percent = pageN / cmpt.lastPageNumber();
    p.chapter = null;
  }


  function setPercentageThrough(cmpt, percent) {
    p.component = cmpt;
    p.percent = percent;
    p.chapter = null;
  }


  function componentId() {
    return p.component.properties.id;
  }


  // How far we are through the component at the "top of the page".
  //
  // 0 - start of book. 1.0 - end of book.
  //
  function percentAtTopOfPage() {
    return p.percent - 1.0 / p.component.lastPageNumber();
  }


  // How far we are through the component at the "bottom of the page".
  //
  // NB: API aliases this to percentageThrough().
  //
  function percentAtBottomOfPage() {
    return p.percent;
  }


  // The page number at a given point (0: start, 1: end) within the component.
  //
  function pageAtPercentageThrough(percent) {
    return Math.max(Math.round(p.component.lastPageNumber() * percent), 1);
  }


  // The page number of this point within the component.
  //
  function pageNumber() {
    return pageAtPercentageThrough(p.percent);
  }


  function chapterInfo() {
    if (p.chapter) {
      return p.chapter;
    }
    return p.chapter = p.component.chapterForPage(pageNumber());
  }


  function chapterTitle() {
    var chp = chapterInfo();
    return chp ? chp.title : null;
  }


  function chapterSrc() {
    var src = componentId();
    var cinfo = chapterInfo();
    if (cinfo && cinfo.fragment) {
      src += "#" + cinfo.fragment;
    }
    return src;
  }


  function getLocus(options) {
    options = options || {};
    var locus = {
      page: pageNumber(),
      componentId: componentId()
    }
    if (options.direction) {
      locus.page += options.direction;
      var lastPageNum = p.component.lastPageNumber();
      if (locus.page > lastPageNum) {
        if (locus.componentId == p.lastCIndex) {
          locus.page = lastPageNum;
          locus.boundaryend = true;
        } else {
          var componentIds = p.component.properties.book.properties.componentIds;
          var cIndex = componentIds.indexOf(locus.componentId);
          locus.load = true;
          locus.componentId = componentIds[cIndex + 1];
          locus.page -= lastPageNum;
        }
      }
    } else {
      locus.percent = percentAtBottomOfPage();
      var props = p.component.properties;
      if (props.layout) {
        locus.layout = props.layout;
      }
      if (props.orientation) {
        locus.orientation = props.orientation;
      }
      if (props.spread) {
        locus.spread = props.spread;
      }
      if (props.pageSpread) {
        locus.pageSpread = props.pageSpread;
      }
      if (props.dimensions) {
        locus.dimensions = props.dimensions;
      }
    }
    return locus;
  }


  // Returns how far this place is in the entire book (0 - start, 1.0 - end).
  //
  function percentageOfBook() {
    componentIds = p.component.properties.book.properties.componentIds;
    componentSize = 1.0 / componentIds.length;
    var pc = componentIds.indexOf(componentId()) * componentSize;
    pc += componentSize * p.percent;
    return pc;
  }


  function onFirstPageOfBook() {
    return p.component.properties.index == 0 && pageNumber() == 1;
  }


  function onLastPageOfBook() {
    return (
      p.component.properties.index ==
        p.component.properties.book.properties.lastCIndex &&
      pageNumber() == p.component.lastPageNumber()
    );
  }

  function onLastPageOfComponent() {
    return pageNumber() == p.component.lastPageNumber();
  }

  function evenPageNumber() {
    return pageNumber() % 2 == 0;
  }

  function oddPageNumber() {
    return pageNumber() % 2 == 1;
  }


  API.setPlace = setPlace;
  API.setPercentageThrough = setPercentageThrough;
  API.componentId = componentId;
  API.percentAtTopOfPage = percentAtTopOfPage;
  API.percentAtBottomOfPage = percentAtBottomOfPage;
  API.percentageThrough = percentAtBottomOfPage;
  API.pageAtPercentageThrough = pageAtPercentageThrough;
  API.pageNumber = pageNumber;
  API.chapterInfo = chapterInfo;
  API.chapterTitle = chapterTitle;
  API.chapterSrc = chapterSrc;
  API.getLocus = getLocus;
  API.percentageOfBook = percentageOfBook;
  API.onFirstPageOfBook = onFirstPageOfBook;
  API.onLastPageOfBook = onLastPageOfBook;
  API.onLastPageOfComponent = onLastPageOfComponent;
  API.evenPageNumber = evenPageNumber;
  API.oddPageNumber = oddPageNumber;

  return API;
}


Monocle.Place.FromPageNumber = function (component, pageNumber) {
  var place = new Monocle.Place();
  place.setPlace(component, pageNumber);
  return place;
}


Monocle.Place.FromPercentageThrough = function (component, percent) {
  var place = new Monocle.Place();
  place.setPercentageThrough(component, percent);
  return place;
}


// We can't create a place from a percentage of the book, because the
// component may not have been loaded yet. But we can get a locus.
//
Monocle.Place.percentOfBookToLocus = function (reader, percent) {
  var componentIds = reader.getBook().properties.componentIds;
  var componentSize = 1.0 / componentIds.length;
  return {
    componentId: componentIds[Math.floor(percent / componentSize)],
    percent: (percent % componentSize) / componentSize
  }
}

Monocle.pieceLoaded('core/place');
/* COMPONENT */

// See the properties declaration for details of constructor arguments.
//
Monocle.Component = function (book, id, index, chapters, source) {

  var API = { constructor: Monocle.Component }
  var k = API.constants = API.constructor;
  var p = API.properties = {
    // a back-reference to the public API of the book that owns this component
    book: book,

    // the string that represents this component in the book's component array
    id: id,

    // the position in the book's components array of this component
    index: index,

    // The chapters argument is an array of objects that list the chapters that
    // can be found in this component. A chapter object is defined as:
    //
    //  {
    //     title: str,
    //     fragment: str, // optional anchor id
    //     percent: n     // how far into the component the chapter begins
    //  }
    //
    // NOTE: the percent property is calculated by the component - you only need
    // to pass in the title and the optional id string.
    //
    chapters: chapters,

    // the frame provided by dataSource.getComponent() for this component
    source: source
  }


  // Makes this component the active component for the pageDiv. There are
  // several strategies for this (see loadFrame).
  //
  // When the component has been loaded into the pageDiv's frame, the callback
  // will be invoked with the pageDiv and this component as arguments.
  //
  function applyTo(pageDiv, callback) {
    var evtData = { 'page': pageDiv, 'source': p.source };
    pageDiv.m.reader.dispatchEvent('monocle:componentchanging', evtData);

    var props = this.properties;
    if (props.layout == "pre-paginated" && props.dimensions) {
      pageDiv.style.width  = props.dimensions[0] + "px";
      pageDiv.style.height = props.dimensions[1] + "px";
    } else {
      pageDiv.style.width  = null;
      pageDiv.style.height = null;
    }

    var onLoaded = function () {
      setupFrame(
        pageDiv,
        pageDiv.m.activeFrame,
        function () { callback(pageDiv, API) }
      );
    }

    Monocle.defer(function () { loadFrame(pageDiv, onLoaded); });
  }


  // Loads this component into the given frame, using one of the following
  // strategies:
  //
  // * HTML - a HTML string
  // * URL - a URL string
  // * Nodes - an array of DOM body nodes (NB: no way to populate head)
  // * Document - a DOM DocumentElement object
  //
  function loadFrame(pageDiv, callback) {
    var frame = pageDiv.m.activeFrame;

    // We own this frame now.
    frame.m.component = API;

    // Hide the frame while we're changing it.
    frame.style.visibility = "hidden";

    // Prevent about:blank overriding imported nodes in Firefox.
    // Disabled again because it seems to result in blank pages in Saf.
    //frame.contentWindow.stop();

    if (p.source.html || (typeof p.source == "string")) {   // HTML
      return loadFrameFromHTML(p.source.html || p.source, frame, callback);
    } else if (p.source.javascript) {                       // JAVASCRIPT
      //console.log("Loading as javascript: "+p.source.javascript);
      return loadFrameFromJavaScript(p.source.javascript, frame, callback);
    } else if (p.source.url) {                              // URL
      return loadFrameFromURL(p.source.url, frame, callback);
    } else if (p.source.nodes) {                            // NODES
      return loadFrameFromNodes(p.source.nodes, frame, callback);
    } else if (p.source.doc) {                              // DOCUMENT
      return loadFrameFromDocument(p.source.doc, frame, callback);
    }
  }


  // LOAD STRATEGY: HTML
  // Loads a HTML string into the given frame, invokes the callback once loaded.
  //
  // Cleans the string so it can be used in a JavaScript statement. This is
  // slow, so if the string is already clean, skip this and use
  // loadFrameFromJavaScript directly.
  //
  function loadFrameFromHTML(src, frame, callback) {
    if ("srcdoc" in document.createElement("iframe")) {
      frame.onload = callback;
      frame.setAttribute("srcdoc", src);
      return;
    }

    // Compress whitespace.
    src = src.replace(/\n/g, '\\n').replace(/\r/, '\\r');

    // Escape single-quotes.
    src = src.replace(/\'/g, '\\\'');

    // Remove scripts. (DISABLED -- Monocle should leave this to implementers.)
    //var scriptFragment = "<script[^>]*>([\\S\\s]*?)<\/script>";
    //src = src.replace(new RegExp(scriptFragment, 'img'), '');

    // BROWSERHACK: Gecko chokes on the DOCTYPE declaration.
    if (Monocle.Browser.is.Gecko) {
      var doctypeFragment = "<!DOCTYPE[^>]*>";
      src = src.replace(new RegExp(doctypeFragment, 'm'), '');
    }

    loadFrameFromJavaScript(src, frame, callback);
  }


  // LOAD STRATEGY: JAVASCRIPT
  // Like the HTML strategy, but assumes that the src string is already clean.
  //
  function loadFrameFromJavaScript(src, frame, callback) {
    src = "javascript:'"+src+"';";
    var cb = function () {
      if (frame.onload) {
        frame.onload = null;
        Monocle.defer(callback);
      }
    }
    frame.onload = cb;
    Monocle.defer(cb, 10000);
    frame.src = src;
  }


  // LOAD STRATEGY: URL
  // Loads the URL into the given frame, invokes callback once loaded.
  //
  function loadFrameFromURL(url, frame, callback) {
    // If it's a relative path, we need to make it absolute, using the
    // reader's location (not the active component's location).
    if (!url.match(/^\//)) {
      var link = document.createElement('a');
      link.setAttribute('href', url);
      url = link.href;
      delete(link);
    }
    frame.onload = function () {
      frame.onload = null;
      Monocle.defer(callback);
    }
    frame.contentWindow.location.replace(url);
  }


  // LOAD STRATEGY: NODES
  // Loads the array of DOM nodes into the body of the frame (replacing all
  // existing nodes), then invokes the callback.
  //
  function loadFrameFromNodes(nodes, frame, callback) {
    var destDoc = frame.contentDocument;
    destDoc.documentElement.innerHTML = "";
    var destHd = destDoc.createElement("head");
    var destBdy = destDoc.createElement("body");

    for (var i = 0; i < nodes.length; ++i) {
      var node = destDoc.importNode(nodes[i], true);
      destBdy.appendChild(node);
    }

    var oldHead = destDoc.getElementsByTagName('head')[0];
    if (oldHead) {
      destDoc.documentElement.replaceChild(destHd, oldHead);
    } else {
      destDoc.documentElement.appendChild(destHd);
    }
    if (destDoc.body) {
      destDoc.documentElement.replaceChild(destBdy, destDoc.body);
    } else {
      destDoc.documentElement.appendChild(destBdy);
    }

    if (callback) { callback(); }
  }


  // LOAD STRATEGY: DOCUMENT
  // Replaces the DocumentElement of the given frame with the given srcDoc.
  // Invokes the callback when loaded.
  //
  function loadFrameFromDocument(srcDoc, frame, callback) {
    var destDoc = frame.contentDocument;

    var srcBases = srcDoc.getElementsByTagName('base');
    if (srcBases[0]) {
      var head = destDoc.getElementsByTagName('head')[0];
      if (!head) {
        try {
          head = destDoc.createElement('head');
          if (destDoc.body) {
            destDoc.insertBefore(head, destDoc.body);
          } else {
            destDoc.appendChild(head);
          }
        } catch (e) {
          head = destDoc.body;
        }
      }
      var bases = destDoc.getElementsByTagName('base');
      var base = bases[0] ? bases[0] : destDoc.createElement('base');
      base.setAttribute('href', srcBases[0].getAttribute('href'));
      head.appendChild(base);
    }

    destDoc.replaceChild(
      destDoc.importNode(srcDoc.documentElement, true),
      destDoc.documentElement
    );

    // DISABLED: immediate readiness - webkit has some difficulty with this.
    // if (callback) { callback(); }

    Monocle.defer(callback);
  }


  // Once a frame is loaded with this component, call this method to style
  // and measure its contents.
  //
  function setupFrame(pageDiv, frame, callback) {
    // iOS touch events on iframes are busted. See comments in
    // events.js for an explanation of this hack.
    //
    Monocle.Events.listenOnIframe(frame);

    var doc = frame.contentDocument;
    var evtData = { 'page': pageDiv, 'document': doc, 'component': API };

    // Announce that the component is loaded.
    pageDiv.m.reader.dispatchEvent('monocle:componentmodify', evtData);

    updateDimensions(pageDiv, function () {
      frame.style.visibility = "visible";

      // Find the place of any chapters in the component.
      locateChapters(pageDiv);

      // Announce that the component has changed.
      pageDiv.m.reader.dispatchEvent('monocle:componentchange', evtData);

      callback();
    });
  }


  // Checks whether the pageDiv dimensions have changed. If they have,
  // remeasures dimensions and returns true. Otherwise returns false.
  //
  function updateDimensions(pageDiv, callback) {
    pageDiv.m.dimensions.update(function (pageLength) {
      p.pageLength = pageLength;
      if (typeof callback == "function") { callback() };
    });
  }


  // Iterates over all the chapters that are within this component
  // (according to the array we were provided on initialization) and finds
  // their location (in percentage terms) within the text.
  //
  // Stores this percentage with the chapter object in the chapters array.
  //
  function locateChapters(pageDiv) {
    if (p.chapters[0] && typeof p.chapters[0].percent == "number") {
      return;
    }
    var doc = pageDiv.m.activeFrame.contentDocument;
    for (var i = 0; i < p.chapters.length; ++i) {
      var chp = p.chapters[i];
      chp.percent = 0;
      if (chp.fragment) {
        var node = doc.getElementById(chp.fragment);
        chp.percent = pageDiv.m.dimensions.percentageThroughOfNode(node);
      }
    }
    return p.chapters;
  }


  // For a given page number within the component, return the chapter that
  // starts on or most-recently-before this page.
  //
  // Useful, for example, in displaying the current chapter title as a
  // running head on the page.
  //
  function chapterForPage(pageN) {
    var cand = null;
    var percent = (pageN - 1) / p.pageLength;
    for (var i = 0; i < p.chapters.length; ++i) {
      if (percent >= p.chapters[i].percent) {
        cand = p.chapters[i];
      } else {
        return cand;
      }
    }
    return cand;
  }


  // For a given chapter fragment (the bit after the hash
  // in eg, "index.html#foo"), return the page number on which
  // the chapter starts. If the fragment is null or blank, will
  // return the first page of the component.
  //
  function pageForChapter(fragment, pageDiv) {
    if (!fragment) {
      return 1;
    }
    for (var i = 0; i < p.chapters.length; ++i) {
      if (p.chapters[i].fragment == fragment) {
        return percentToPageNumber(p.chapters[i].percent);
      }
    }
    var doc = pageDiv.m.activeFrame.contentDocument;
    var node = doc.getElementById(fragment);
    var percent = pageDiv.m.dimensions.percentageThroughOfNode(node);
    return percentToPageNumber(percent);
  }


  function pageForXPath(xpath, pageDiv) {
    var doc = pageDiv.m.activeFrame.contentDocument;
    var percent = 0;
    if (Monocle.Browser.env.supportsXPath) {
      var node = doc.evaluate(xpath, doc, null, 9, null).singleNodeValue;
      if (node) {
        percent = pageDiv.m.dimensions.percentageThroughOfNode(node);
      }
    } else {
      console.warn("XPath not supported in this client.");
    }
    return percentToPageNumber(percent);
  }


  function pageForSelector(selector, pageDiv) {
    var doc = pageDiv.m.activeFrame.contentDocument;
    var percent = 0;
    if (Monocle.Browser.env.supportsQuerySelector) {
      var node = doc.querySelector(selector);
      if (node) {
        percent = pageDiv.m.dimensions.percentageThroughOfNode(node);
      }
    } else {
      console.warn("querySelector not supported in this client.");
    }
    return percentToPageNumber(percent);
  }


  function percentToPageNumber(pc) {
    return Math.floor(pc * p.pageLength) + 1;
  }


  // A public getter for p.pageLength.
  //
  function lastPageNumber() {
    return (p.layout == "pre-paginated") ? 1 : p.pageLength;
  }


  API.applyTo = applyTo;
  API.updateDimensions = updateDimensions;
  API.chapterForPage = chapterForPage;
  API.pageForChapter = pageForChapter;
  API.pageForXPath = pageForXPath;
  API.pageForSelector = pageForSelector;
  API.lastPageNumber = lastPageNumber;

  return API;
}

Monocle.pieceLoaded('core/component');
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
// The simplest page-flipping interaction system: contact to the left half of
// the reader turns back one page, contact to the right half turns forward
// one page.
//
Monocle.Panels.TwoPane = function (flipper, evtCallbacks) {

  var API = { constructor: Monocle.Panels.TwoPane }
  var k = API.constants = API.constructor;
  var p = API.properties = {}


  function initialize() {
    p.panels = {
      forwards: new Monocle.Controls.Panel(),
      backwards: new Monocle.Controls.Panel()
    }

    for (dir in p.panels) {
      flipper.properties.reader.addControl(p.panels[dir]);
      p.panels[dir].listenTo(evtCallbacks);
      p.panels[dir].properties.direction = flipper.constants[dir.toUpperCase()];
      var style = { "width": k.WIDTH };
      style[(dir == "forwards" ? "right" : "left")] = 0;
      p.panels[dir].properties.div.dom.setStyles(style);
    }
  }


  initialize();

  return API;
}

Monocle.Panels.TwoPane.WIDTH = "50%";

Monocle.pieceLoaded('panels/twopane');
// A three-pane system of page interaction. The left 33% turns backwards, the
// right 33% turns forwards, and contact on the middle third causes the
// system to go into "interactive mode". In this mode, the page-flipping panels
// are only active in the margins, and all of the actual text content of the
// book is selectable. The user can exit "interactive mode" by hitting the little
// IMode icon in the lower right corner of the reader.
//
Monocle.Panels.IMode = function (flipper, evtCallbacks) {

  var API = { constructor: Monocle.Panels.IMode }
  var k = API.constants = API.constructor;
  var p = API.properties = {}


  function initialize() {
    p.flipper = flipper;
    p.reader = flipper.properties.reader;
    p.panels = {
      forwards: new Monocle.Controls.Panel(),
      backwards: new Monocle.Controls.Panel()
    }
    p.divs = {}

    for (dir in p.panels) {
      p.reader.addControl(p.panels[dir]);
      p.divs[dir] = p.panels[dir].properties.div;
      p.panels[dir].listenTo(evtCallbacks);
      p.panels[dir].properties.direction = flipper.constants[dir.toUpperCase()];
      p.divs[dir].style.width = "33%";
      p.divs[dir].style[dir == "forwards" ? "right" : "left"] = 0;
    }

    p.panels.central = new Monocle.Controls.Panel();
    p.reader.addControl(p.panels.central);
    p.divs.central = p.panels.central.properties.div;
    p.divs.central.dom.setStyles({ left: "33%", width: "34%" });
    menuCallbacks({ end: modeOn });

    for (dir in p.panels) {
      p.divs[dir].dom.addClass('panels_imode_panel');
      p.divs[dir].dom.addClass('panels_imode_'+dir+'Panel');
    }

    p.toggleIcon = {
      createControlElements: function (cntr) {
        var div = cntr.dom.make('div', 'panels_imode_toggleIcon');
        Monocle.Events.listenForTap(div, modeOff);
        return div;
      }
    }
    p.reader.addControl(p.toggleIcon, null, { hidden: true });
  }


  function menuCallbacks(callbacks) {
    p.menuCallbacks = callbacks;
    p.panels.central.listenTo(p.menuCallbacks);
  }


  function toggle() {
    p.interactive ? modeOff() : modeOn();
  }


  function modeOn() {
    if (p.interactive) {
      return;
    }

    p.panels.central.contract();

    var page = p.reader.visiblePages()[0];
    var sheaf = page.m.sheafDiv;
    var bw = sheaf.offsetLeft;
    var fw = page.offsetWidth - (sheaf.offsetLeft + sheaf.offsetWidth);
    bw = Math.floor(((bw - 2) / page.offsetWidth) * 10000 / 100 ) + "%";
    fw = Math.floor(((fw - 2) / page.offsetWidth) * 10000 / 100 ) + "%";

    startCameo(function () {
      p.divs.forwards.style.width = fw;
      p.divs.backwards.style.width = bw;
      Monocle.Styles.affix(p.divs.central, 'transform', 'translateY(-100%)');
    });

    p.reader.showControl(p.toggleIcon);

    p.interactive = true;
    if (flipper.interactiveMode) {
      flipper.interactiveMode(true);
    }
  }


  function modeOff() {
    if (!p.interactive) {
      return;
    }

    p.panels.central.contract();

    deselect();

    startCameo(function () {
      p.divs.forwards.style.width = "33%";
      p.divs.backwards.style.width = "33%";
      Monocle.Styles.affix(p.divs.central, 'transform', 'translateY(0)');
    });

    p.reader.hideControl(p.toggleIcon);

    p.interactive = false;
    if (flipper.interactiveMode) {
      flipper.interactiveMode(false);
    }
  }


  function startCameo(fn) {
    // Set transitions on the panels.
    var trn = Monocle.Panels.IMode.CAMEO_DURATION+"ms ease-in";
    Monocle.Styles.affix(p.divs.forwards, 'transition', "width "+trn);
    Monocle.Styles.affix(p.divs.backwards, 'transition', "width "+trn);
    Monocle.Styles.affix(p.divs.central, 'transition', "-webkit-transform "+trn);

    // Temporarily disable listeners.
    for (var pan in p.panels) {
      p.panels[pan].deafen();
    }

    // Set the panels to opaque.
    for (var div in p.divs) {
      p.divs[div].style.opacity = 1;
    }

    if (typeof WebkitTransitionEvent != "undefined") {
      p.cameoListener = Monocle.Events.listen(
        p.divs.central,
        'webkitTransitionEnd',
        endCameo
      );
    } else {
      setTimeout(endCameo, k.CAMEO_DURATION);
    }
    fn();
  }


  function endCameo() {
    setTimeout(function () {
      // Remove panel transitions.
      var trn = "opacity linear " + Monocle.Panels.IMode.LINGER_DURATION + "ms";
      Monocle.Styles.affix(p.divs.forwards, 'transition', trn);
      Monocle.Styles.affix(p.divs.backwards, 'transition', trn);
      Monocle.Styles.affix(p.divs.central, 'transition', trn);

      // Set the panels to transparent.
      for (var div in p.divs) {
        p.divs[div].style.opacity = 0;
      }

      // Re-enable listeners.
      p.panels.forwards.listenTo(evtCallbacks);
      p.panels.backwards.listenTo(evtCallbacks);
      p.panels.central.listenTo(p.menuCallbacks);
    }, Monocle.Panels.IMode.LINGER_DURATION);


    if (p.cameoListener) {
      Monocle.Events.deafen(p.divs.central, 'webkitTransitionEnd', endCameo);
    }
  }


  function deselect() {
    for (var i = 0, cmpt; cmpt = p.reader.dom.find('component', i); ++i) {
      var sel = cmpt.contentWindow.getSelection() || cmpt.contentDocument.selection;
      //if (sel.collapse) { sel.collapse(true); }
      if (sel.removeAllRanges) { sel.removeAllRanges(); }
      if (sel.empty) { sel.empty(); }
      cmpt.contentDocument.body.scrollLeft = 0;
      cmpt.contentDocument.body.scrollTop = 0;
    }
  }


  API.toggle = toggle;
  API.modeOn = modeOn;
  API.modeOff = modeOff;
  API.menuCallbacks = menuCallbacks;

  initialize();

  return API;
}

Monocle.Panels.IMode.CAMEO_DURATION = 250;
Monocle.Panels.IMode.LINGER_DURATION = 250;

Monocle.pieceLoaded('panels/imode');
Monocle.Panels.eInk = function (flipper, evtCallbacks) {

  var API = { constructor: Monocle.Panels.eInk }
  var k = API.constants = API.constructor;
  var p = API.properties = {
    flipper: flipper
  }


  function initialize() {
    p.panel = new Monocle.Controls.Panel();
    p.reader = p.flipper.properties.reader;
    p.reader.addControl(p.panel);

    p.panel.listenTo({ end: function (panel, x) {
      if (x < p.panel.properties.div.offsetWidth / 2) {
        p.panel.properties.direction = flipper.constants.BACKWARDS;
      } else {
        p.panel.properties.direction = flipper.constants.FORWARDS;
      }
      evtCallbacks.end(panel, x);
    } });

    var s = p.panel.properties.div.style;
    p.reader.listen("monocle:componentchanging", function () {
      s.opacity = 1;
      Monocle.defer(function () { s.opacity = 0 }, 40);
    });
    s.width = "100%";
    s.background = "#000";
    s.opacity = 0;

    if (k.LISTEN_FOR_KEYS) {
      Monocle.Events.listen(window.top.document, 'keyup', handleKeyEvent);
    }
  }


  function handleKeyEvent(evt) {
    var eventCharCode = evt.charCode || evt.keyCode;
    var dir = null;
    if (eventCharCode == k.KEYS["PAGEUP"]) {
      dir = flipper.constants.BACKWARDS;
    } else if (eventCharCode == k.KEYS["PAGEDOWN"]) {
      dir = flipper.constants.FORWARDS;
    }
    if (dir) {
      flipper.moveTo({ direction: dir });
      evt.preventDefault();
    }
  }


  initialize();

  return API;
}


Monocle.Panels.eInk.LISTEN_FOR_KEYS = true;
Monocle.Panels.eInk.KEYS = { "PAGEUP": 33, "PAGEDOWN": 34 };
// Provides page-flipping panels only in the margins of the book. This is not
// entirely suited to small screens with razor-thin margins, but is an
// appropriate panel class for larger screens (like, say, an iPad).
//
// Since the flipper hit zones are only in the margins, the actual text content
// of the book is always selectable.
//
Monocle.Panels.Marginal = function (flipper, evtCallbacks) {

  var API = { constructor: Monocle.Panels.Marginal }
  var k = API.constants = API.constructor;
  var p = API.properties = {}


  function initialize() {
    p.panels = {
      forwards: new Monocle.Controls.Panel(),
      backwards: new Monocle.Controls.Panel()
    }

    for (dir in p.panels) {
      flipper.properties.reader.addControl(p.panels[dir]);
      p.panels[dir].listenTo(evtCallbacks);
      p.panels[dir].properties.direction = flipper.constants[dir.toUpperCase()];
      with (p.panels[dir].properties.div.style) {
        dir == "forwards" ? right = 0 : left = 0;
      }
    }
    setWidths();

    if (flipper.interactiveMode) {
      flipper.interactiveMode(true);
    }
  }


  function setWidths() {
    var page = flipper.properties.reader.dom.find('page');
    var sheaf = page.m.sheafDiv;
    var bw = sheaf.offsetLeft;
    var fw = page.offsetWidth - (sheaf.offsetLeft + sheaf.offsetWidth);
    bw = Math.floor(((bw - 2) / page.offsetWidth) * 10000 / 100 ) + "%";
    fw = Math.floor(((fw - 2) / page.offsetWidth) * 10000 / 100 ) + "%";
    p.panels.forwards.properties.div.style.width = fw;
    p.panels.backwards.properties.div.style.width = bw;
  }


  API.setWidths = setWidths;

  initialize();

  return API;
}

Monocle.pieceLoaded('panels/marginal');
Monocle.Dimensions.Vert = function (pageDiv) {

  var API = { constructor: Monocle.Dimensions.Vert }
  var k = API.constants = API.constructor;
  var p = API.properties = {
    page: pageDiv,
    reader: pageDiv.m.reader
  }


  function initialize() {
    p.reader.listen('monocle:componentchange', componentChanged);
  }


  function update(callback) {
    p.bodyHeight = getBodyHeight();
    p.pageHeight = getPageHeight();
    p.length = Math.ceil(p.bodyHeight / p.pageHeight);
    callback(p.length);
  }


  function getBodyHeight() {
    return p.page.m.activeFrame.contentDocument.body.scrollHeight;
  }


  function getPageHeight() {
    return p.page.m.activeFrame.offsetHeight - k.GUTTER;
  }


  function percentageThroughOfNode(target) {
    if (!target) {
      return 0;
    }
    var doc = p.page.m.activeFrame.contentDocument;
    var offset = 0;
    if (target.getBoundingClientRect) {
      offset = target.getBoundingClientRect().top;
      offset -= doc.body.getBoundingClientRect().top;
    } else {
      var oldScrollTop = doc.body.scrollTop;
      target.scrollIntoView();
      offset = doc.body.scrollTop;
      doc.body.scrollLeft = 0;
      doc.body.scrollTop = oldScrollTop;
    }

    //console.log(id + ": " + offset + " of " + p.bodyHeight);
    var percent = offset / p.bodyHeight;
    return percent;
  }


  function componentChanged(evt) {
    if (evt.m['page'] != p.page) { return; }
    var sheaf = p.page.m.sheafDiv;
    var cmpt = p.page.m.activeFrame;
    sheaf.dom.setStyles(k.SHEAF_STYLES);
    cmpt.dom.setStyles(k.COMPONENT_STYLES);
    var doc = evt.m['document'];
    doc.documentElement.style.overflow = 'hidden';
    doc.body.style.marginRight = '10px !important';
    cmpt.contentWindow.scrollTo(0,0);
  }


  function locusToOffset(locus) {
    return p.pageHeight * (locus.page - 1);
  }


  API.update = update;
  API.percentageThroughOfNode = percentageThroughOfNode;
  API.locusToOffset = locusToOffset;

  initialize();

  return API;
}

Monocle.Dimensions.Vert.GUTTER = 10;

Monocle.pieceLoaded("dimensions/vert");
Monocle.Flippers.Legacy = function (reader) {

  var API = { constructor: Monocle.Flippers.Legacy }
  var k = API.constants = API.constructor;
  var p = API.properties = {
    pageCount: 1,
    divs: {}
  }


  function initialize() {
    p.reader = reader;
  }


  function addPage(pageDiv) {
    pageDiv.m.dimensions = new Monocle.Dimensions.Vert(pageDiv);
  }


  function getPlace() {
    return page().m.place;
  }


  function moveTo(locus, callback) {
    var fn = frameToLocus;
    if (typeof callback == "function") {
      fn = function (locus) { frameToLocus(locus); callback(locus); }
    }
    p.reader.getBook().setOrLoadPageAt(page(), locus, fn);
  }


  function listenForInteraction(panelClass) {
    if (typeof panelClass != "function") {
      panelClass = k.DEFAULT_PANELS_CLASS;
      if (!panelClass) {
        console.warn("Invalid panel class.")
      }
    }
    p.panels = new panelClass(API, { 'end': turn });
  }


  function page() {
    return p.reader.dom.find('page');
  }


  function turn(panel) {
    var dir = panel.properties.direction;
    var place = getPlace();
    if (
      (dir < 0 && place.onFirstPageOfBook()) ||
      (dir > 0 && place.onLastPageOfBook())
    ) { return; }
    moveTo({ page: getPlace().pageNumber() + dir });
  }


  function frameToLocus(locus) {
    var cmpt = p.reader.dom.find('component');
    var win = cmpt.contentWindow;
    var srcY = scrollPos(win);
    var dims = page().m.dimensions;
    var pageHeight = dims.properties.pageHeight;
    var destY = dims.locusToOffset(locus);

    //console.log(srcY + " => " + destY);
    if (Math.abs(destY - srcY) > pageHeight) {
      return win.scrollTo(0, destY);
    }

    showIndicator(win, srcY < destY ? srcY + pageHeight : srcY);
    Monocle.defer(
      function () { smoothScroll(win, srcY, destY, 300, scrollingFinished); },
      150
    );
  }


  function scrollPos(win) {
    // Firefox, Chrome, Opera, Safari
    if (win.pageYOffset) {
      return win.pageYOffset;
    }
    // Internet Explorer 6 - standards mode
    if (win.document.documentElement && win.document.documentElement.scrollTop) {
      return win.document.documentElement.scrollTop;
    }
    // Internet Explorer 6, 7 and 8
    if (win.document.body.scrollTop) {
      return win.document.body.scrollTop;
    }
    return 0;
  }


  function smoothScroll(win, currY, finalY, duration, callback) {
    clearTimeout(win.smoothScrollInterval);
    var stamp = (new Date()).getTime();
    var frameRate = 40;
    var step = (finalY - currY) * (frameRate / duration);
    var stepFn = function () {
      var destY = currY + step;
      if (
        (new Date()).getTime() - stamp > duration ||
        Math.abs(currY - finalY) < Math.abs((currY + step) - finalY)
      ) {
        clearTimeout(win.smoothScrollInterval);
        win.scrollTo(0, finalY);
        if (callback) { callback(); }
      } else {
        win.scrollTo(0, destY);
        currY = destY;
      }
    }
    win.smoothScrollInterval = setInterval(stepFn, frameRate);
  }


  function scrollingFinished() {
    hideIndicator(page().m.activeFrame.contentWindow);
    p.reader.dispatchEvent('monocle:turn');
  }


  function showIndicator(win, pos) {
    if (p.hideTO) { clearTimeout(p.hideTO); }

    var doc = win.document;
    if (!doc.body.indicator) {
      doc.body.indicator = createIndicator(doc);
      doc.body.appendChild(doc.body.indicator);
    }
    doc.body.indicator.line.style.display = "block";
    doc.body.indicator.style.opacity = 1;
    positionIndicator(pos);
  }


  function hideIndicator(win) {
    var doc = win.document;
    p.hideTO = Monocle.defer(
      function () {
        if (!doc.body.indicator) {
          doc.body.indicator = createIndicator(doc);
          doc.body.appendChild(doc.body.indicator);
        }
        var dims = page().m.dimensions;
        positionIndicator(
          dims.locusToOffset(getPlace().getLocus()) + dims.properties.pageHeight
        )
        doc.body.indicator.line.style.display = "none";
        doc.body.indicator.style.opacity = 0.5;
      },
      600
    );
  }


  function createIndicator(doc) {
    var iBox = doc.createElement('div');
    doc.body.appendChild(iBox);
    Monocle.Styles.applyRules(iBox, k.STYLES.iBox);

    iBox.arrow = doc.createElement('div');
    iBox.appendChild(iBox.arrow);
    Monocle.Styles.applyRules(iBox.arrow, k.STYLES.arrow);

    iBox.line = doc.createElement('div');
    iBox.appendChild(iBox.line);
    Monocle.Styles.applyRules(iBox.line, k.STYLES.line);

    return iBox;
  }


  function positionIndicator(y) {
    var p = page();
    var doc = p.m.activeFrame.contentDocument;
    var maxHeight = p.m.dimensions.properties.bodyHeight;
    maxHeight -= doc.body.indicator.offsetHeight;
    if (y > maxHeight) {
      y = maxHeight;
    }
    doc.body.indicator.style.top = y + "px";
  }


  // THIS IS THE CORE API THAT ALL FLIPPERS MUST PROVIDE.
  API.pageCount = p.pageCount;
  API.addPage = addPage;
  API.getPlace = getPlace;
  API.moveTo = moveTo;
  API.listenForInteraction = listenForInteraction;

  initialize();

  return API;
}

Monocle.Flippers.Legacy.FORWARDS = 1;
Monocle.Flippers.Legacy.BACKWARDS = -1;
Monocle.Flippers.Legacy.DEFAULT_PANELS_CLASS = Monocle.Panels.TwoPane;

Monocle.Flippers.Legacy.STYLES = {
  iBox: {
    'position': 'absolute',
    'right': 0,
    'left': 0,
    'height': '10px'
  },
  arrow: {
    'position': 'absolute',
    'right': 0,
    'height': '10px',
    'width': '10px',
    'background': '#333',
    'border-radius': '6px'
  },
  line: {
    'width': '100%',
    'border-top': '2px dotted #333',
    'margin-top': '5px'
  }
}

Monocle.pieceLoaded('flippers/legacy');
Monocle.Dimensions.Columns = function (pageDiv) {

  var API = { constructor: Monocle.Dimensions.Columns }
  var k = API.constants = API.constructor;
  var p = API.properties = {
    page: pageDiv,
    reader: pageDiv.m.reader,
    length: 0,
    width: 0
  }

  // Logically, forceColumn browsers can't have a gap, because that would
  // make the minWidth > 200%. But how much greater? Not worth the effort.
  k.GAP = Monocle.Browser.env.forceColumns ? 0 : 20;

  function update(callback) {
    setColumnWidth();
    Monocle.defer(function () {
      p.length = columnCount();
      if (Monocle.DEBUG) {
        console.log(
          'page['+p.page.m.pageIndex+'] -> '+p.length+
          ' ('+p.page.m.activeFrame.m.component.properties.id+')'
        );
      }
      callback(p.length);
    });
  }


  function setColumnWidth() {
    var pdims = pageDimensions();
    var ce = columnedElement();

    p.width = pdims.width;

    var rules = Monocle.Styles.rulesToString(k.STYLE["columned"]);
    rules += Monocle.Browser.css.toCSSDeclaration('column-width', pdims.col+'px');
    rules += Monocle.Browser.css.toCSSDeclaration('column-gap', k.GAP+'px');
    rules += Monocle.Browser.css.toCSSDeclaration('column-fill', 'auto');
    rules += Monocle.Browser.css.toCSSDeclaration('transform', 'translateX(0)');

    if (Monocle.Browser.env.forceColumns && ce.scrollHeight > pdims.height) {
      rules += Monocle.Styles.rulesToString(k.STYLE['column-force']);
      if (Monocle.DEBUG) {
        console.warn("Force columns ("+ce.scrollHeight+" > "+pdims.height+")");
      }
    }

    if (ce.style.cssText != rules) {
      // Update offset because we're translating to zero.
      p.page.m.offset = 0;

      // Apply body style changes.
      ce.style.cssText = rules;

      if (Monocle.Browser.env.scrollToApplyStyle) {
        ce.scrollLeft = 0;
      }
    }
  }


  // Returns the element to which columns CSS should be applied.
  //
  function columnedElement() {
    return p.page.m.activeFrame.contentDocument.body;
  }


  // Returns the width of the offsettable area of the columned element. By
  // definition, the number of pages is always this divided by the
  // width of a single page (eg, the client area of the columned element).
  //
  function columnedWidth() {
    var bd = columnedElement();
    var de = p.page.m.activeFrame.contentDocument.documentElement;

    var w = Math.max(bd.scrollWidth, de.scrollWidth);

    // Add one because the final column doesn't have right gutter.
    w += k.GAP;

    if (!Monocle.Browser.env.widthsIgnoreTranslate && p.page.m.offset) {
      w += p.page.m.offset;
    }
    return w;
  }


  function pageDimensions() {
    var elem = p.page.m.sheafDiv;
    return {
      col: elem.clientWidth,
      width: elem.clientWidth + k.GAP,
      height: elem.clientHeight
    }
  }


  function columnCount() {
    return Math.ceil(columnedWidth() / pageDimensions().width)
  }


  function locusToOffset(locus) {
    return pageDimensions().width * (locus.page - 1);
  }


  // Moves the columned element to the offset implied by the locus.
  //
  // The 'transition' argument is optional, allowing the translation to be
  // animated. If not given, no change is made to the columned element's
  // transition property.
  //
  function translateToLocus(locus, transition) {
    var offset = locusToOffset(locus);
    p.page.m.offset = offset;
    translateToOffset(offset, transition);
    return offset;
  }


  function translateToOffset(offset, transition) {
    var ce = columnedElement();
    if (transition) {
      Monocle.Styles.affix(ce, "transition", transition);
    }
    Monocle.Styles.affix(ce, "transform", "translateX(-"+offset+"px)");
  }


  function percentageThroughOfNode(target) {
    if (!target) { return 0; }
    var doc = p.page.m.activeFrame.contentDocument;
    var offset = 0;
    if (Monocle.Browser.env.findNodesByScrolling) {
      // First, remove translation...
      translateToOffset(0);

      // Store scroll offsets for all windows.
      var win = s = p.page.m.activeFrame.contentWindow;
      var scrollers = [
        [win, win.scrollX, win.scrollY],
        [window, window.scrollX, window.scrollY]
      ];
      //while (s != s.parent) { scrollers.push([s, s.scrollX]); s = s.parent; }

      if (Monocle.Browser.env.sheafIsScroller) {
        var scroller = p.page.m.sheafDiv;
        var x = scroller.scrollLeft;
        target.scrollIntoView();
        offset = scroller.scrollLeft;
      } else {
        var scroller = win;
        var x = scroller.scrollX;
        target.scrollIntoView();
        offset = scroller.scrollX;
      }

      // Restore scroll offsets for all windows.
      while (s = scrollers.shift()) {
        s[0].scrollTo(s[1], s[2]);
      }

      // ... finally, replace translation.
      translateToOffset(p.page.m.offset);
    } else {
      offset = target.getBoundingClientRect().left;
      offset -= doc.body.getBoundingClientRect().left;
    }

    // We know at least 1px will be visible, and offset should not be 0.
    offset += 1;

    // Percent is the offset divided by the total width of the component.
    var percent = offset / (p.length * p.width);

    // Page number would be offset divided by the width of a single page.
    // var pageNum = Math.ceil(offset / pageDimensions().width);

    return percent;
  }


  API.update = update;
  API.percentageThroughOfNode = percentageThroughOfNode;

  API.locusToOffset = locusToOffset;
  API.translateToLocus = translateToLocus;

  return API;
}


Monocle.Dimensions.Columns.STYLE = {
  // Most of these are already applied to body, but they're repeated here
  // in case columnedElement() is ever anything other than body.
  "columned": {
    "margin": "0",
    "padding": "0",
    "height": "100%",
    "width": "100%",
    "position": "absolute"
  },
  "column-force": {
    "min-width": "200%",
    "overflow": "hidden"
  }
}

Monocle.pieceLoaded("dimensions/columns");
Monocle.Flippers.Slider = function (reader) {
  if (Monocle.Flippers == this) {
    return new Monocle.Flippers.Slider(reader);
  }

  var API = { constructor: Monocle.Flippers.Slider }
  var k = API.constants = API.constructor;
  var p = API.properties = {
    pageCount: 2,
    activeIndex: 1,
    turnData: {}
  }


  function initialize() {
    p.reader = reader;
    p.reader.listen("monocle:componentchanging", showWaitControl);
  }


  function addPage(pageDiv) {
    pageDiv.m.dimensions = new Monocle.Dimensions.Columns(pageDiv);

    // BROWSERHACK: Firefox 4 is prone to beachballing on the first page turn
    // unless a zeroed translateX has been applied to the page div.
    Monocle.Styles.setX(pageDiv, 0);
  }


  function visiblePages() {
    return [upperPage()];
  }


  function listenForInteraction(panelClass) {
    // BROWSERHACK: Firstly, prime interactiveMode for buggy iOS WebKit.
    interactiveMode(true);
    interactiveMode(false);

    if (typeof panelClass != "function") {
      panelClass = k.DEFAULT_PANELS_CLASS;
      if (!panelClass) {
        console.warn("Invalid panel class.")
      }
    }
    var q = function (action, panel, x) {
      var dir = panel.properties.direction;
      if (action == "lift") {
        lift(dir, x);
      } else if (action == "release") {
        release(dir, x);
      }
    }
    p.panels = new panelClass(
      API,
      {
        'start': function (panel, x) { q('lift', panel, x); },
        'move': function (panel, x) { turning(panel.properties.direction, x); },
        'end': function (panel, x) { q('release', panel, x); },
        'cancel': function (panel, x) { q('release', panel, x); }
      }
    );
  }


  // A panel can call this with true/false to indicate that the user needs
  // to be able to select or otherwise interact with text.
  function interactiveMode(bState) {
    p.reader.dispatchEvent('monocle:interactive:'+(bState ? 'on' : 'off'));
    if (!Monocle.Browser.env.selectIgnoresZOrder) { return; }
    if (p.interactive = bState) {
      if (p.activeIndex != 0) {
        var place = getPlace();
        if (place) {
          setPage(
            p.reader.dom.find('page', 0),
            place.getLocus(),
            function () {
              flipPages();
              prepareNextPage();
            }
          );
        } else {
          flipPages();
        }
      }
    }
  }


  function getPlace(pageDiv) {
    pageDiv = pageDiv || upperPage();
    return pageDiv.m ? pageDiv.m.place : null;
  }


  function moveTo(locus, callback) {
    var fn = function () {
      prepareNextPage(function () {
        if (typeof callback == "function") { callback(); }
        announceTurn();
      });
    }
    setPage(upperPage(), locus, fn);
  }


  function setPage(pageDiv, locus, callback) {
    p.reader.getBook().setOrLoadPageAt(
      pageDiv,
      locus,
      function (locus) {
        pageDiv.m.dimensions.translateToLocus(locus);
        Monocle.defer(callback);
      }
    );
  }


  function upperPage() {
    return p.reader.dom.find('page', p.activeIndex);
  }


  function lowerPage() {
    return p.reader.dom.find('page', (p.activeIndex + 1) % 2);
  }


  function flipPages() {
    upperPage().style.zIndex = 1;
    lowerPage().style.zIndex = 2;
    return p.activeIndex = (p.activeIndex + 1) % 2;
  }


  function lift(dir, boxPointX) {
    if (p.turnData.lifting || p.turnData.releasing) { return; }

    p.turnData.points = {
      start: boxPointX,
      min: boxPointX,
      max: boxPointX
    }
    p.turnData.lifting = true;

    var place = getPlace();

    if (dir == k.FORWARDS) {
      if (place.onLastPageOfBook()) {
        p.reader.dispatchEvent(
          'monocle:boundaryend',
          {
            locus: getPlace().getLocus({ direction : dir }),
            page: upperPage()
          }
        );
        resetTurnData();
        return;
      }
      onGoingForward(boxPointX);
    } else if (dir == k.BACKWARDS) {
      if (place.onFirstPageOfBook()) {
        p.reader.dispatchEvent(
          'monocle:boundarystart',
          {
            locus: getPlace().getLocus({ direction : dir }),
            page: upperPage()
          }
        );
        resetTurnData();
        return;
      }
      onGoingBackward(boxPointX);
    } else {
      console.warn("Invalid direction: " + dir);
    }
  }


  function turning(dir, boxPointX) {
    if (!p.turnData.points) { return; }
    if (p.turnData.lifting || p.turnData.releasing) { return; }
    checkPoint(boxPointX);
    slideToCursor(boxPointX, null, "0");
  }


  function release(dir, boxPointX) {
    if (!p.turnData.points) {
      return;
    }
    if (p.turnData.lifting) {
      p.turnData.releaseArgs = [dir, boxPointX];
      return;
    }
    if (p.turnData.releasing) {
      return;
    }

    checkPoint(boxPointX);

    p.turnData.releasing = true;

    if (dir == k.FORWARDS) {
      if (
        p.turnData.points.tap ||
        p.turnData.points.start - boxPointX > 60 ||
        p.turnData.points.min >= boxPointX
      ) {
        // Completing forward turn
        slideOut(afterGoingForward);
      } else {
        // Cancelling forward turn
        slideIn(afterCancellingForward);
      }
    } else if (dir == k.BACKWARDS) {
      if (
        p.turnData.points.tap ||
        boxPointX - p.turnData.points.start > 60 ||
        p.turnData.points.max <= boxPointX
      ) {
        // Completing backward turn
        slideIn(afterGoingBackward);
      } else {
        // Cancelling backward turn
        slideOut(afterCancellingBackward);
      }
    } else {
      console.warn("Invalid direction: " + dir);
    }
  }


  function checkPoint(boxPointX) {
    p.turnData.points.min = Math.min(p.turnData.points.min, boxPointX);
    p.turnData.points.max = Math.max(p.turnData.points.max, boxPointX);
    p.turnData.points.tap = p.turnData.points.max - p.turnData.points.min < 10;
  }


  function onGoingForward(x) {
    lifted(x);
  }


  function onGoingBackward(x) {
    var lp = lowerPage(), up = upperPage();

    // set lower to "the page before upper"
    setPage(
      lp,
      getPlace(up).getLocus({ direction: k.BACKWARDS }),
      function () {
        // flip lower to upper, ready to slide in from left
        flipPages();
        // move lower off the screen to the left
        jumpOut(lp, function () {
          lifted(x);
        });
      }
    );
  }


  function afterGoingForward() {
    var up = upperPage(), lp = lowerPage();
    if (p.interactive) {
      // set upper (off screen) to current
      setPage(
        up,
        getPlace().getLocus({ direction: k.FORWARDS }),
        function () {
          // move upper back onto screen, then set lower to next and reset turn
          jumpIn(up, function () { prepareNextPage(announceTurn); });
        }
      );
    } else {
      flipPages();
      jumpIn(up, function () { prepareNextPage(announceTurn); });
    }
  }


  function afterGoingBackward() {
    if (p.interactive) {
      // set lower page to current
      setPage(
        lowerPage(),
        getPlace().getLocus(),
        function () {
          // flip lower to upper
          flipPages();
          // set lower to next and reset turn
          prepareNextPage(announceTurn);
        }
      );
    } else {
      announceTurn();
    }
  }


  function afterCancellingForward() {
    resetTurnData();
  }


  function afterCancellingBackward() {
    flipPages(); // flip upper to lower
    jumpIn(lowerPage(), function () { prepareNextPage(resetTurnData); });
  }


  function prepareNextPage(callback) {
    setPage(
      lowerPage(),
      getPlace().getLocus({ direction: k.FORWARDS }),
      callback
    );
  }


  function lifted(x) {
    p.turnData.lifting = false;
    var releaseArgs = p.turnData.releaseArgs;
    if (releaseArgs) {
      p.turnData.releaseArgs = null;
      release(releaseArgs[0], releaseArgs[1]);
    } else if (x) {
      slideToCursor(x);
    }
  }


  function announceTurn() {
    p.reader.dispatchEvent('monocle:turn');
    resetTurnData();
  }


  function resetTurnData() {
    hideWaitControl();
    p.turnData = {};
  }


  function setX(elem, x, options, callback) {
    var duration, transition;

    if (!options.duration) {
      duration = 0;
    } else {
      duration = parseInt(options.duration);
    }

    if (Monocle.Browser.env.supportsTransition) {
      Monocle.Styles.transitionFor(
        elem,
        'transform',
        duration,
        options.timing,
        options.delay
      );

      if (Monocle.Browser.env.supportsTransform3d) {
        Monocle.Styles.affix(elem, 'transform', 'translate3d('+x+'px,0,0)');
      } else {
        Monocle.Styles.affix(elem, 'transform', 'translateX('+x+'px)');
      }

      if (typeof callback == "function") {
        if (duration && Monocle.Styles.getX(elem) != x) {
          Monocle.Events.afterTransition(elem, callback);
        } else {
          Monocle.defer(callback);
        }
      }
    } else {
      // Old-school JS animation.
      elem.currX = elem.currX || 0;
      var completeTransition = function () {
        elem.currX = x;
        Monocle.Styles.setX(elem, x);
        if (typeof callback == "function") { callback(); }
      }
      if (!duration) {
        completeTransition();
      } else {
        var stamp = (new Date()).getTime();
        var frameRate = 40;
        var step = (x - elem.currX) * (frameRate / duration);
        var stepFn = function () {
          var destX = elem.currX + step;
          var timeElapsed = ((new Date()).getTime() - stamp) >= duration;
          var pastDest = (destX > x && elem.currX < x) ||
            (destX < x && elem.currX > x);
          if (timeElapsed || pastDest) {
            completeTransition();
          } else {
            Monocle.Styles.setX(elem, destX);
            elem.currX = destX;
            setTimeout(stepFn, frameRate);
          }
        }
        stepFn();
      }
    }
  }


  function jumpIn(pageDiv, callback) {
    opts = { duration: (Monocle.Browser.env.stickySlideOut ? 1 : 0) }
    setX(pageDiv, 0, opts, callback);
  }


  function jumpOut(pageDiv, callback) {
    setX(pageDiv, 0 - pageDiv.offsetWidth, { duration: 0 }, callback);
  }


  // NB: Slides are always done by the visible upper page.

  function slideIn(callback) {
    setX(upperPage(), 0, slideOpts(), callback);
  }


  function slideOut(callback) {
    setX(upperPage(), 0 - upperPage().offsetWidth, slideOpts(), callback);
  }


  function slideToCursor(cursorX, callback, duration) {
    setX(
      upperPage(),
      Math.min(0, cursorX - upperPage().offsetWidth),
      { duration: duration || k.FOLLOW_DURATION },
      callback
    );
  }


  function slideOpts() {
    var opts = { timing: 'ease-in', duration: 320 }
    var now = (new Date()).getTime();
    if (p.lastSlide && now - p.lastSlide < 1500) { opts.duration *= 0.5; }
    p.lastSlide = now;
    return opts;
  }


  function ensureWaitControl() {
    if (p.waitControl) { return; }
    p.waitControl = {
      createControlElements: function (holder) {
        return holder.dom.make('div', 'flippers_slider_wait');
      }
    }
    p.reader.addControl(p.waitControl, 'page');
  }


  function showWaitControl() {
    ensureWaitControl();
    p.reader.dom.find('flippers_slider_wait', 0).style.opacity = 1;
    p.reader.dom.find('flippers_slider_wait', 1).style.opacity = 1;
  }


  function hideWaitControl() {
    ensureWaitControl();
    p.reader.dom.find('flippers_slider_wait', 0).style.opacity = 0;
    p.reader.dom.find('flippers_slider_wait', 1).style.opacity = 0;
  }


  // THIS IS THE CORE API THAT ALL FLIPPERS MUST PROVIDE.
  API.pageCount = p.pageCount;
  API.addPage = addPage;
  API.getPlace = getPlace;
  API.moveTo = moveTo;
  API.listenForInteraction = listenForInteraction;

  // OPTIONAL API - WILL BE INVOKED (WHERE RELEVANT) IF PROVIDED.
  API.visiblePages = visiblePages;
  API.interactiveMode = interactiveMode;

  initialize();

  return API;
}


// Constants
Monocle.Flippers.Slider.DEFAULT_PANELS_CLASS = Monocle.Panels.TwoPane;
Monocle.Flippers.Slider.FORWARDS = 1;
Monocle.Flippers.Slider.BACKWARDS = -1;
Monocle.Flippers.Slider.FOLLOW_DURATION = 100;

Monocle.pieceLoaded('flippers/slider');
Monocle.Flippers.Scroller = function (reader, setPageFn) {

  var API = { constructor: Monocle.Flippers.Scroller }
  var k = API.constants = API.constructor;
  var p = API.properties = {
    pageCount: 1,
    duration: 300
  }


  function initialize() {
    p.reader = reader;
    p.setPageFn = setPageFn;
  }


  function addPage(pageDiv) {
    pageDiv.m.dimensions = new Monocle.Dimensions.Columns(pageDiv);
  }


  function page() {
    return p.reader.dom.find('page');
  }


  function listenForInteraction(panelClass) {
    if (typeof panelClass != "function") {
      panelClass = k.DEFAULT_PANELS_CLASS;
    }
    p.panels = new panelClass(
      API,
      {
        'end': function (panel) { turn(panel.properties.direction); }
      }
    );
  }


  function turn(dir) {
    if (p.turning) { return; }
    moveTo({ page: getPlace().pageNumber() + dir});
  }


  function getPlace() {
    return page().m.place;
  }


  function moveTo(locus, callback) {
    var fn = frameToLocus;
    if (typeof callback == "function") {
      fn = function (locus) { frameToLocus(locus); callback(locus); }
    }
    p.reader.getBook().setOrLoadPageAt(page(), locus, fn);
  }


  function frameToLocus(locus) {
    if (locus.boundarystart || locus.boundaryend) { return; }
    p.turning = true;
    var dims = page().m.dimensions;
    var fr = page().m.activeFrame;
    var bdy = fr.contentDocument.body;
    var anim = true;
    if (p.activeComponent != fr.m.component) {
      // No animation.
      p.activeComponent = fr.m.component;
      dims.translateToLocus(locus, "none");
      Monocle.defer(turned);
    } else if (Monocle.Browser.env.supportsTransition) {
      // Native animation.
      dims.translateToLocus(locus, p.duration+"ms ease-in 0ms");
      Monocle.Events.afterTransition(bdy, turned);
    } else {
      // Old-school JS animation.
      var x = dims.locusToOffset(locus);
      var finalX = 0 - x;
      var stamp = (new Date()).getTime();
      var frameRate = 40;
      var currX = p.currX || 0;
      var step = (finalX - currX) * (frameRate / p.duration);
      var stepFn = function () {
        var destX = currX + step;
        if (
          (new Date()).getTime() - stamp > p.duration ||
          Math.abs(currX - finalX) <= Math.abs((currX + step) - finalX)
        ) {
          Monocle.Styles.setX(bdy, finalX);
          turned();
        } else {
          Monocle.Styles.setX(bdy, destX);
          currX = destX;
          setTimeout(stepFn, frameRate);
        }
        p.currX = destX;
      }
      stepFn();
    }
  }


  function turned() {
    p.turning = false;
    p.reader.dispatchEvent('monocle:turn');
  }


  // THIS IS THE CORE API THAT ALL FLIPPERS MUST PROVIDE.
  API.pageCount = p.pageCount;
  API.addPage = addPage;
  API.getPlace = getPlace;
  API.moveTo = moveTo;
  API.listenForInteraction = listenForInteraction;

  initialize();

  return API;
}

Monocle.Flippers.Scroller.speed = 200; // How long the animation takes
Monocle.Flippers.Scroller.rate = 20; // frame-rate of the animation
Monocle.Flippers.Scroller.FORWARDS = 1;
Monocle.Flippers.Scroller.BACKWARDS = -1;
Monocle.Flippers.Scroller.DEFAULT_PANELS_CLASS = Monocle.Panels.TwoPane;


Monocle.pieceLoaded('flippers/scroller');
Monocle.Flippers.Instant = function (reader) {

  var API = { constructor: Monocle.Flippers.Instant }
  var k = API.constants = API.constructor;
  var p = API.properties = {
    pageCount: 1
  }


  function initialize() {
    p.reader = reader;
  }


  function addPage(pageDiv) {
    pageDiv.m.dimensions = new Monocle.Dimensions.Columns(pageDiv);
  }


  function getPlace() {
    return page().m.place;
  }


  function moveTo(locus, callback) {
    var fn = frameToLocus;
    if (typeof callback == "function") {
      fn = function (locus) { frameToLocus(locus); callback(locus); }
    }
    p.reader.getBook().setOrLoadPageAt(page(), locus, fn);
  }


  function listenForInteraction(panelClass) {
    if (typeof panelClass != "function") {
      if (Monocle.Browser.on.Kindle3) {
        panelClass = Monocle.Panels.eInk;
      }
      panelClass = panelClass || k.DEFAULT_PANELS_CLASS;
    }
    if (!panelClass) { throw("Panels not found."); }
    p.panels = new panelClass(API, { 'end': turn });
  }


  function page() {
    return p.reader.dom.find('page');
  }


  function turn(panel) {
    var dir = panel.properties.direction;
    moveTo({ page: getPlace().pageNumber() + dir});
  }


  function frameToLocus(locus) {
    page().m.dimensions.translateToLocus(locus);
    Monocle.defer(function () { p.reader.dispatchEvent('monocle:turn'); });
  }


  // THIS IS THE CORE API THAT ALL FLIPPERS MUST PROVIDE.
  API.pageCount = p.pageCount;
  API.addPage = addPage;
  API.getPlace = getPlace;
  API.moveTo = moveTo;
  API.listenForInteraction = listenForInteraction;

  initialize();

  return API;
}

Monocle.Flippers.Instant.FORWARDS = 1;
Monocle.Flippers.Instant.BACKWARDS = -1;
Monocle.Flippers.Instant.DEFAULT_PANELS_CLASS = Monocle.Panels.TwoPane;



Monocle.pieceLoaded('flippers/instant');
























Monocle.pieceLoaded('monocore');
