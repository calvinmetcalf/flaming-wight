class PouchCore
	constructor: (@remoteUrl,@onChange)->
		if @remoteUrl.slice(0,4)=="http" #did we get a real url?
			parts = @remoteUrl.split("/") #split the url bu by the slashes
			@_dbName = parts.pop() #assign the last part as the db name
			while @_dbName == "" #unless it is an empty string
				@_dbName = parts.pop()#repeat until you find one
		Pouch @_dbName, (e, db) => #making the local db
			unless e #error would imply we are on an old browser
				@db = db
				@db.changes(
					continuous : true
					include_docs : true
					onChange : @onChange
				)
				#we replicate
				_to=@db.replicate.to @remoteUrl,{continuous: true}
				_from=@db.replicate.from @remoteUrl, {continuous: true}
				@up=true
				@stop = ()=>
					console.log "stopped"
					@up=false
					_to.cancel()
					_from.cancel()
					@
				@start = ()=>
					unless @up
						@up=true
						_to=@db.replicate.to @remoteUrl,{continuous: true}
						_from=@db.replicate.from @remoteUrl, {continuous: true}
					@
				@
			else #there was an error lets try again but just with the remote one
				Pouch @remoteUrl, (e, db) =>
					unless e
						@db
						@db.changes(
							continuous : true
							include_docs : true
							onChange : @onChange
						)
						@
					else
						return "yeah something went wrong"
	add: (doc, cb = ()-> true) ->
		unless "_id" of doc
			@db.post doc, cb
		else if "_id" of doc and doc._id.slice(0,8) != "_design/"
			@db.put doc, cb
		else if doc.length
			@db.bulkDocs doc, cb
	get: (id, cb = ()-> true) ->
		@db.get id, cb
	remove: (id, cb = ()-> true) ->
		@get id, (err, doc) =>
			@db.remove doc, cb unless err
			cb("err") if err
templateText  = """<div class="navbar navbar-inverse navbar-fixed-top">
      <div class="navbar-inner">
        <div class="container-fluid">
          <a class="btn btn-navbar" data-toggle="collapse" data-target=".nav-collapse">
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
          </a>
       <a class="brand" href="home" id="home">Pouch Demo</a>
           <div class="nav-collapse collapse">
       <ul class="nav">
            
               <li id="noteLink" {{#newNote}}class='active'{{/newNote}}><a id="newNote" href="newNote">New</a></li>
            </ul>
      
            <ul class="nav pull-right" >

 
            <li><a href="start" id="toggleStart"><i class="icon-refresh"></i></a></li>
            </ul>
          </div><!--/.nav-collapse -->
        </div>
      </div>
    </div>
  
 
<br/><br/><br/><div class="container-fluid">
  	<div class="row-fluid">
  	<div class="span2">
          <div class="well sidebar-nav" id="sidebar">
            <ul class="nav nav-list" id="sideList"><li class='nav-header'>Notes</li>
          {{#sideList}}
          <li id='li{{key}}' {{#active}}class='active'{{/active}}><a href='#{'#'}{{key}}' id='{{key}}'>{{{title}}}</a></li>
          {{/sideList}}
            </ul>
          </div><!--/.well -->
        </div>
    	<div class="span10">
      <div  id="mainContent">{{^edit}}{{> content}}{{/edit}}{{#edit}}{{> editContent}}{{/edit}}</div>
    	</div>
  	</div>
	</div>"""
template = Mustache.compile templateText
Mustache.compilePartial("content","<h1>{{title}}{{#editable}}<a id='editable' href='edit{{hash}}'><i class ='icon-edit' id='edit{{hash}}'></i></a>{{/editable}}</h1><p>{{#md}}{{{body}}}{{/md}}</p>")
Mustache.compilePartial("editContent","""
	
    
  <form class="form" id="updateForm">
  <div class="tabbable tabs-left">
  <ul class="nav nav-tabs">
   <li  class="active"><a href="#tab1" data-toggle="tab">edit</a></li>
   <li><a href="#tab2" data-toggle="tab">view</a></li>
  </ul>
  <div class="tab-content">
  <div class="tab-pane active" id="tab1">	
  
  
  
  
  
  
		<div class="control-group">
    <label class="control-label" for="noteTitle">Title</label>
    <div class="controls">
      
 <input type="text" id="noteTitle" name="title" value='{{title}}'>
    </div>
  </div>
  <div class="control-group">
    <label class="control-label" for="nodeBody">Your Note</label>
    <div class="controls">
      <textarea rows="10" id="noteBody" class="span8" name='body'>{{{body}}}</textarea></div>
  </div>
  
  
  
     </div><div class="tab-pane" id="tab2"></div>
       </div>
</div>
  
  
  
  <div class="control-group">
    <div class="controls" id="btg">
      <button type="submit" class="btn btn-success" id="updateNote">Update</button>
      <button type="submit" class="btn btn-info" id="cancelUpdate">Cancel Edit</buton>
      <button type="submit" class="btn btn-danger" id="deleteNote">Delete</button>
    </div>
  </div>
</form>
   
    """)
obj={}
converter = new Showdown.converter()
update = ->
	window.views = {sideList : []}
	if location.hash == ""
		hash="home"
		location.hash="home"
	else if location.hash.slice(0,5) == '#edit'
		hash = location.hash.slice(5)
		views.edit = true
	else
		hash = location.hash.slice(1)
	if hash not of obj
		hash = "home"
	for key of obj
		if hash == key
			views.title=obj[key].title
			views.body=obj[key].body
			views[key]=true
		if "type" of obj[key] and obj[key].type == "note"
			item = {key:key,title:obj[key].title}
			if hash == key
				views.editable=true
				item.active=true
			else
				item.active=false
			views.sideList.push item
	views.up = pouch.up
	views.hash = hash
	views.md =()->
		(text, render)->
			converter.makeHtml(render(text))
	if views.title is "New Note"
		views.newNote = true
	$("#body").empty().append(template(views))
	if views.edit or views.title is "New Note"
		ta = $("#noteBody")
		t2 = $("#tab2")
		tt = $("#noteTitle")
		ch=()->
			t2.empty().append("<h3>#{tt.val()}</h3>"+converter.makeHtml(ta.val()))
		ch()
		ta.on "change", ch
		tt.on "change", ch
	document.title = views.title
$ ()->
	linkaction = (e)->
		if e.target.id != ""# and "login"  "logout"
			location.hash = e.target.id
			e.preventDefault()
			update()
		true
	$("#body").on "click","a",linkaction
	$("#body").on "click","#editable",(e)->
		e.preventDefault()
		location.hash = location.hash.slice 1
		update()
	$("#body").on "click","#dontNote", ()->
		e.preventDefault()
		location.hash = "home"
		update()
	$("#body").on "submit","#noteForm", (e)->
		e.preventDefault()
		results = 
			body : $("#noteBody").val()
			title : $("#noteTitle").val()
			type : "note"
		pouch.add results, (err, resp)->
			location.hash = resp.id
			update()
		false
	$("#body").on "click","#updateNote",(e)->
		e.preventDefault()
		if location.hash.slice(0,5) == '#edit'
			docid =location.hash.slice(5)
			pouch.get  docid, (err,doc)->
				return if err or doc.type isnt "note"
				doc.body =$("#noteBody").val()
				doc.title=$("#noteTitle").val()
				pouch.add doc
				location.hash = docid
				update()
				true
	$("#body").on "click","#deleteNote",(e)->
		e.preventDefault()
		if location.hash.slice(0,5) == '#edit'
			docid =location.hash.slice(5)
			pouch.remove docid, ()->
				location.hash ="home"
				update()
			true
	$("#body").on "click","#cancelUpdate",(e)->
		e.preventDefault()
		location.hash="home"
		update()
	$("#body").on "click","#toggleStart",(e)->
		e.preventDefault()
		pouch.stop().start()
		update()
	true
window.onpopstate=()->
	update()
window.pouch = new PouchCore location.protocol + "//"+ location.host + "/pd", (change)=>
	if change.id[0] isnt "_" and (change.doc.type is 'note' or change.doc.type is 'page')
		unless change.doc._deleted
			obj[change.id] = change.doc
			update()
		else if change.doc._deleted and change.id of obj
			delete obj[change.id]
			update()
