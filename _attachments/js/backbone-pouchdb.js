// Store models in *PouchDB*.
Backbone.sync = (function() {
  // match read request to get, query or allDocs call
  function read(db, model, callback) {
    // get single model
    if (model.id) return db.get(model.id, callback);


    // all docs
    db.db.allDocs({include_docs:true}, callback);
  }

  // the sync adapter function
  var sync = function(method, model, options) {
    var db = this.db

    options || (options = {});
    options.error || (options.error = function() {});
    options.success || (options.success = function() {});

 

    function callback(err, resp) {
      err === null ? options.success(resp) : options.error(err);
    }

 
      switch (method) {
        case "read":   read(db, model, callback);           break;
        case "create": db.add(model.toJSON(),  callback);   break;
        case "update": db.add(model.toJSON(), callback);    break;
        case "delete": 
        	if (model.id) {
        		db.remove(model.id, callback); break;
        	} else {
        		db.db.remove(model.toJSON(), callback); break;
        	}
      }
 
  };

  // extend the sync adapter function
  // to init pouch via Backbone.sync.pouch(url, options)
  sync.pouch = function(db) {
     sync.prototype.db = db;
  };

  return sync;
})();