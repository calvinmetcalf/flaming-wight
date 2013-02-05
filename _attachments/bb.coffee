templates=
	topNav:"""
		<ul class="nav">
			{{#topList}}
				<li id='li{{_id}}' {{#active}}class='active'{{/active}}>
					<a class='nogo{{#brand}} brand{{/brand}}'href='{{_id}}' id='{{_id}}'>{{{title}}}</a>
				</li>
			{{/topList}}
		</ul>
		<ul class="nav pull-right" >
			<li>
				<a href="start" id="toggleStart"><i class="icon-refresh"></i></a>
			</li>
		</ul>
	"""
	sideList:"""
		<li class='nav-header'>Notes</li>
		{{#sideList}}
			<li id='li{{_id}}' {{#active}}class='active'{{/active}}>
				<a class="nogo" href='{{_id}}' id='{{_id}}'>{{{title}}}</a>
			</li>
		{{/sideList}}
	"""
	mainContent:"""
		{{^edit}}
			<h1>{{title}}{{#editable}}<a id='edit{{_id}}' class="nogo" href='edit{{_id}}'><i class ='icon-edit' id='edit{{_id}}'></i></a>{{/editable}}</h1>
			<p>{{#md}}{{{body}}}{{/md}}</p>
		{{/edit}}
		{{#edit}}
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
									<input type="text" id="noteTitle" name="title" value='{{title}}' class="forMD">
								</div>
							</div>
							<div class="control-group">
								<label class="control-label" for="nodeBody">Your Note</label>
								<div class="controls">
									<textarea rows="10" id="noteBody" class="span8 forMD" name='body'>{{{body}}}</textarea></div>
								</div>
							</div>
							<div class="tab-pane" id="tab2"></div>
						</div>
					</div>
					<div class="control-group">
						<div class="controls" id="btg">
							<button type="submit" class="btn btn-success" id="updateNote">Update</button>
							<button type="reset" class="btn btn-info" id="cancelUpdate">Cancel Edit</buton>
							<button type="button" class="btn btn-danger" id="deleteNote">Delete</button>
						</div>
					</div>
			</form>
		{{/edit}}
	"""

class Item extends Backbone.Model
	idAttribute: "_id"
	defaults : ()->
		active : false
	validate:(attr)->
		if 'title' not of attr or attr.title is ''
			return 'needs a title'
		else
			return

class Items extends Backbone.Collection
	model: Item

items = new Items
		
class genericView extends Backbone.View
	initialize: () =>
		@collection.on 'add', @handleUpdate, @
		@collection.on 'remove', @handleUpdate, @
		@collection.on 'change:active', @updateActive, @
		_.each @options.fields, (v)=>
			@collection.on 'change:'+v,@handleUpdate,@
		@render = @options.render
		@template = (Mustache.compile @options.template)
		@converter = new Showdown.converter()
		@md = ()=>
			(text, render)=>
				@converter.makeHtml(render(text))
	setActive : (e)=>
		e.preventDefault()
		routes.navigate e.target.id,{trigger:true}
	updateActive : (e)=>
		@render() if @belongs(e)
		if e.changed.active
			oldActive = @collection.where(_.extend({},@options.which,{active:true})).filter((v)->e.id isnt v.id)
			if oldActive.length > 0
				_.each oldActive,(v)=>
					@collection.get(v.id).set "active", false
		true
	handleUpdate : (e)=>
		@render() if @belongs(e)
	belongs : (v)=>
		if "which" not of @options
			return v
		else 
			for key of @options.which
				if v.get(key) != @options.which[key]
					return false
			return v
	renderMD:()=>
		innterTemplate = Mustache.compile "<h3>{{title}}</h3>{{#md}}{{body}}{{/md}}"
		renderedBody = @$("#tab2")
		note =
			body : @$("#noteBody").val()
			title : @$("#noteTitle").val()
			md : @md
		renderedBody.html(innterTemplate(note))
	makeNote : (e)=>
		note =
			body : @$("#noteBody").val()
			title : @$("#noteTitle").val()
			_id : Math.uuid()
			type : "note"
		@collection.add note
		e.preventDefault()
		routes.navigate note._id,{trigger:true}
	resetNote : (e)=>
		e.preventDefault()
		id = @collection.where({'active':true})[0].id
		if id == '#newNote'
			routes.navigate 'home', {trigger:true}
		else
			routes.navigate id,{trigger:true}
	updateNote : (e)=>
		e.preventDefault()
		id = @collection.where({'active':true})[0].id
		@collection.get(id).set
			body : @$("#noteBody").val()
			title : @$("#noteTitle").val()
			edit : false
		routes.navigate id,{trigger:true}
	deleteNote : (e)=>
		e.preventDefault()
		@collection.remove @collection.get(@collection.where({'active':true})[0].id)
		routes.navigate 'home',{trigger:true}
	restartPouch : (e)=>
		e.preventDefault()
		pouch.stop().start()
	

sideView = new genericView 
	fields : ['title']
	template : templates.sideList
	el : $ "#sideList"
	collection : items
	which : {"type": "note"}
	render : ()->
		obj =
			sideList : @collection.where(@options.which).map((v)->v.toJSON())
		@$el.html(@template(obj))
		@
	events : 
		"click .nogo":"setActive"
topView = new genericView
	fields : ['title']
	template : templates.topNav
	el : $ "#topNav"
	collection : items
	which : {"type":"page"}
	render : ()->
		obj =
			topList : @collection.where(@options.which).map((v)->
				if v.id=='home'
					v.set "brand", true
				v.toJSON())
		obj.topList.sort (a, b) ->
			if a.brand
				0
			else
				1
		@$el.html(@template(obj))
		@
	events : 
		"click .nogo":"setActive"
		"click #toggleStart":"restartPouch"
mainView = new genericView
	fields : ['title', 'body','edit']
	template : templates.mainContent
	el : $ "#mainContent"
	collection : items
	which : {active:true}
	render : ()->
		obj = @collection.where(@options.which)
		if obj.length == 1
			obj=obj[0]
		else
			return
		if obj.get("type") == "note"
			obj.set "editable", true
		obj.set "md", @md
		@$el.html @template(obj.toJSON())
		@renderMD()
		@
	events : 
		"change .forMD" : "renderMD"
		"submit #noteForm" : "makeNote"
		"reset #noteForm" : "resetNote"
		"reset #updateForm" : "resetNote"
		"submit #updateForm" : "updateNote"
		"click #deleteNote" : "deleteNote"
		"click .nogo":"setActive"
class Routes extends Backbone.Router
	routes : 
		'edit:page' : "editPage"
		':page' : "goto"
	editPage:(page)->
		items.get(page).set({"edit":true,"active":true})
	goto : (page)->
		curent = items.get(page)
		firstLoad = (e)->
				if e.id == page
					items.off "change",firstLoad
					e.set {"edit":false,"active":true}
		if curent
			curent.set({"edit":false,"active":true})
		else
			items.on "add",firstLoad,@
					
routes = new Routes
window.pouch = new PouchCore location.protocol + "//"+ location.host + "/backbone", (change)=>
		if change.id[0] isnt "_" and (change.doc.type is 'note' or change.doc.type is 'page')
			unless change.doc._deleted
				items.add change.doc, {merge:true, validate:true}
			else if change.doc._deleted and items.get(change.id)
				items.remove items.get(change.id) 
$ ()->
	root = "/backbone/_design/pouch/_rewrite/"
	#items.add docs, {validate:true}
	Backbone.history.start {root:root,pushState:true,hashChange: false}
	items.on "add change:body change:title", (item)->
		doc = 
			_id : item.get '_id'
			body : item.get 'body'
			title : item.get 'title'
			type : item.get 'type'
		doc._rev = item.get('_rev') if item.get('_rev')
		pouch.add doc
	items.on "remove", (item)->
		pouch.remove item.id
