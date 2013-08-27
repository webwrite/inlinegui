wait = (delay,fn) -> setTimeout(fn,delay)

class File extends Spine.Model
	@configure('File',
		'meta'
		'id'
		'filename'
		'relativePath'
		'date'
		'extension'
		'contentType'
		'encoding'
		'content'
		'contentRendered'
		'url'
		'urls'
	)

	@extend Spine.Model.Ajax

	@url: '/restapi/documents/'

	@fromJSON: (response) ->
		return  unless response

		if Spine.isArray(response.data)
			result = (new @(item)  for item in response.data)
		else
			result = new @(response.data)

		return result

class FileEditItem extends Spine.Controller
	el: $('.editbar').remove().first().prop('outerHTML')

	elements:
		'.field-title  :input': '$title'
		'.field-date   :input': '$date'
		'.field-author :input': '$author'
		'.file-source': '$source'
		'.previewbar': '$iframe'

	render: =>
		# Prepare
		{item, $el, $title, $date, $author, $iframe, $source} = @
		{meta, filename, date, urls} = item

		# Apply
		$title.val  meta?.title or filename or ''
		$date.val   date?.toISOString()
		$source.val ''
		$iframe.attr('src': document.location.origin+'/'+urls[0])
		# @todo figure out why file.url doesn't work

		# Chain
		@

class FileListItem extends Spine.Controller
	el: $('.content-row-file').remove().first().prop('outerHTML')

	elements:
		'.content-title': '$title'
		'.content-tags': '$tags'
		'.content-date': '$date'

	render: =>
		# Prepare
		{item, $el, $title, $tags, $date} = @
		{id, meta, filename, date} = item

		# Apply
		$el.data('file', item)
		$title.text meta?.title or filename or ''
		$tags.text  meta?.tags?.join(', ') or ''
		$date.text  date?.toLocaleDateString() or ''

		# Chain
		@

class App extends Spine.Controller
	editView: null

	elements:
		'window': '$window'
		'.loadbar': '$loadbar'
		'.previewbar': '$previewbar'
		'.navbar': '$navbar'
		'.navbar .link': '$links'
		'.navbar .toggle': '$toggles'
		'.link-site': '$linkSite'
		'.link-page': '$linkPage'
		'.toggle-preview': '$togglePreview'
		'.toggle-meta': '$toggleMeta'
		'.content-table': '$filesList'
		'.content-row-file': '$files'

	events:
		'resize window': 'onWindowResize'
		'click .link-site': 'siteMode'
		'click .button-edit, .content-name': 'pageMode'
		'click .navbar .toggle': 'clickToggle'
		'click .navbar .button': 'clickButton'

	constructor: ->
		# Super
		super

		# Fetch
		File.bind('create', @addFile)
		File.bind('refresh change', @addFiles)
		File.fetch()
		# @todo figure out how to release/destroy files

		# Apply
		@siteMode()
		@onWindowResize()
		@$el.addClass('app-ready')

		# Chain
		@

	addFile: (item) =>
		{$filesList} = @
		view = new FileListItem({item})
		$filesList.append(view.render().el)
		@

	addFiles: =>
		{$files} = @
		$files.remove()
		@addFile(file)  for file in File.all()
		@

	clickButton: (e) =>
		# Prepare
		{$loadbar} = @
		target = e.currentTarget
		$target = $(e.currentTarget)

		# Apply
		if $loadbar.hasClass('active') is false or $loadbar.data('for') is target
			$target
				.toggleClass('active')
				.siblings('.button')
					.toggleClass('disabled')
			$loadbar
				.toggleClass('active')
				.toggleClass($target.data('loadclassname'))
				.data('for', target)

		# Chain
		@

	clickToggle: (e) ->
		# Prepare
		$target = $(e.currentTarget)

		# Apply
		$target.toggleClass('active')

		# Chain
		@

	pageMode: (e) =>
		# Disable click through
		e.preventDefault()
		e.stopPropagation()

		# Clean
		if @editView?
			@editView.release()
			@editView = null

		# Prepare
		{$el, $toggleMeta, $links, $linkPage, $toggles, $togglePreview} = @
		$target = $(e.currentTarget)
		$row = $target.parents('.content-row:first')
		file = $row.data('file')
		title = file.meta.title or file.filename

		# Apply
		$el
			.removeClass('app-site')
			.addClass('app-page')
		$links
			.removeClass('active')
		$linkPage
			.text(title)
			.addClass('active')
		$toggles
			.removeClass('active')
		$togglePreview
			.addClass('active')
		if $target.hasClass('button-edit')
			$toggleMeta
				.addClass('active')

		# View
		@editView = new FileEditItem({item:file})
		$el.append(@editView.render().el)

		# Chain
		@

	siteMode: =>
		# Prepare
		{$el, $linkSite} = @

		# Clean
		if @editView?
			@editView.release()
			@editView = null

		# Apply
		$el
			.removeClass('app-page')
			.addClass('app-site')
		$linkSite
			.addClass('active')
			.siblings().removeClass('active')

		# Chain
		@

	onWindowResize: =>
		# Prepare
		{$previewbar} = @

		# Apply
		$previewbar.css(
			'min-height': @$window.height() - @$navbar.outerHeight()
		)

		# Chain
		@

	onIframeResize: (size) =>
		# Prepare
		{$previewbar} = @

		# Apply
		$previewbar.height(size)

		# Chain
		@

window.app = app = new App(
	el: $('.app')
)
window.resizeIframe = app.onIframeResize.bind(app)
