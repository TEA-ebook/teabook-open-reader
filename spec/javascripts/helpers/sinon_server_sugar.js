(function() {
  var Response;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  Response = (function() {

    function Response(server) {
      this.log = __bind(this.log, this);
      this.restore = __bind(this.restore, this);
      this.queue = __bind(this.queue, this);
      this["default"] = __bind(this["default"], this);
      this["with"] = __bind(this["with"], this);      this.server = server || sinon.fakeServer.create();
      this["default"]();
    }

    Response.prototype["with"] = function(options) {
      var data;
      data = options;
      if (_.isFunction(options.url) && _.isFunction(options.toJSON)) {
        data = {
          url: options.url(),
          content: JSON.stringify(options.toJSON())
        };
      }
      _.extend(this.options, data);
      return this;
    };

    Response.prototype.defaultOptions = function() {
      return {
        method: "GET",
        url: '/',
        status: 200,
        headers: {
          "Content-Type": "application/json"
        },
        content: ''
      };
    };

    Response.prototype["default"] = function() {
      this.options = this.defaultOptions();
      return this;
    };

    Response.prototype.queue = function() {
      this.server.respondWith(this.options.method, this.options.url, [this.options.status, this.options.headers, this.options.content]);
      return this;
    };

    Response.prototype.restore = function() {
      return this.server.restore.call(this.server);
    };

    Response.prototype.log = function() {
      console.log(this.options.method, this.options.url, [this.options.status, this.options.headers, this.options.content]);
      return this;
    };

    return Response;

  })();

  window.Response = Response;

}).call(this);
