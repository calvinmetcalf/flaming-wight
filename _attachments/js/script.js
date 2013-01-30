var PouchCore,
  _this = this;

PouchCore = (function() {
  var parts;

  function PouchCore(remoteUrl, onChange) {
    this.remoteUrl = remoteUrl;
    this.onChange = onChange;
  }

  if (PouchCore.remoteUrl.slice(0, 4) === "http") {
    parts = PouchCore.remoteUrl.split("/");
  }

  PouchCore._dbName = parts.pop();

  while (PouchCore._dbName === "") {
    PouchCore._dbName = parts.pop();
  }

  return PouchCore;

})();

Pouch(this._dbName, function(e, db) {
  if (!e) {
    _this.db = db;
    _this.db.changes({
      continuous: true,
      include_docs: true,
      onChange: _this.onChange
    });
    _this.db.replicate.to(_this.remoteUrl({
      continuous: true
    }));
    _this.db.replicate.from(_this.remoteUrl({
      continuous: true
    }));
    return _this;
  } else {
    return Pouch(_this.remoteUrl, function(e, db) {
      if (!e) {
        _this.db;
        _this.db.changes({
          continuous: true,
          include_docs: true,
          onChange: _this.onChange
        });
        return _this;
      } else {
        return "yeah something went wrong";
      }
    });
  }
});

({
  add: function(doc, cb) {
    if (cb == null) {
      cb = function() {
        return true;
      };
    }
    if (!("_id" in doc)) {
      return this.db.post(doc, cb);
    } else if ("_id" in doc && doc._id.slice(0, 8) !== "_design/") {
      return this.db.put(doc, cb);
    } else if (doc.length) {
      return this.db.bulkDocs(doc, cb);
    }
  },
  get: function(id, cb) {
    if (cb == null) {
      cb = function() {
        return true;
      };
    }
    return this.db.get(id, cb);
  },
  remove: function(id, cb) {
    var _this = this;
    if (cb == null) {
      cb = function() {
        return true;
      };
    }
    return this.get(id, function(err, doc) {
      if (!err) {
        _this.db.remove(doc, cb);
      }
      if (err) {
        return cb("err");
      }
    });
  }
});