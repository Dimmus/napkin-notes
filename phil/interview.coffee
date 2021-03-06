BookConfig = window.Book or {}
BookConfig.includes ?= {}
BookConfig.includes.fontawesome  ?= '//maxcdn.bootstrapcdn.com/font-awesome/4.1.0/css/font-awesome.min.css'
BookConfig.urlFixer ?= (val) -> val
BookConfig.toc ?= {}
BookConfig.toc.url       ?= '../toc'   # or '../SUMMARY' for GitBook
BookConfig.toc.selector  ?= 'nav, ol, ul'  # picks the first one that matches
BookConfig.baseHref ?= null # or '//archive.cnx.org/contents' (for loading resources)
BookConfig.serverAddsTrailingSlash ?= false # Used because jekyll adds trailing slashes
BookConfig.searchIndex ?= null
BookConfig.contributeUrl ?= null
BookConfig.rootUrl = BookConfig.rootUrl or ''


# Inject the <link> tags for FontAwesome
if BookConfig.includes.fontawesome
  fa = document.createElement('link')
  fa.rel = 'stylesheet'
  fa.href = BookConfig.includes.fontawesome
  document.head.appendChild(fa)


BOOK_TEMPLATE = '''
  <div class="book with-summary font-size-2 font-family-1">
    <div class="book-header">
      <a href="#" class="btn pull-left toggle-summary" aria-label="Toggle summary"><i class="fa fa-align-justify"></i></a>
      <a href="#" class="btn pull-left toggle-search" aria-label="Search book"><i class="fa fa-search"></i></a>
      <h1><i class="fa fa-spinner fa-spin book-spinner"></i><span class="book-title"></span></h1>
      <a href="#" target="_blank" class="btn pull-right google-plus-sharing-link sharing-link" data-sharing="google-plus" aria-label="Share on Google Plus"><i class="fa fa-google-plus"></i></a>
      <a href="#" target="_blank" class="btn pull-right facebook-sharing-link sharing-link" data-sharing="facebook" aria-label="Share on Facebook"><i class="fa fa-facebook"></i></a>
      <a href="#" target="_blank" class="btn pull-right twitter-sharing-link sharing-link" data-sharing="twitter" aria-label="Share on Twitter"><i class="fa fa-twitter"></i></a>
    </div>
    <div class="book-summary">
      <div class="book-search">
        <input type="text" placeholder="Search" class="form-control">
      </div>
    </div>
    <div class="book-body">
      <div class="body-inner">
        <div class="page-wrapper" tabindex="-1">
          <div class="book-progress">
            <div class="bar">
              <div class="inner" style="min-width: 0%;"></div>
            </div>
          </div>
          <div class="page-inner">
            <section class="normal">
              <!-- content -->
            </section>
          </div>
        </div>
      </div>
    </div>
  </div>
'''

$ ->
  # Squirrel the body and replace it with the template:
  $body = $('body')
  $originalPage = $body.contents()
  searchIndex = null

  $body.contents().remove()
  $body.append(BOOK_TEMPLATE)

  # Pull out all the interesting DOM nodes from the template
  $book = $body.find('.book')
  $toggleSummary = $book.find('.toggle-summary')
  $toggleSearch = $book.find('.toggle-search')
  $bookSearchInput = $book.find('.book-search .form-control')
  $bookSummary = $book.find('.book-summary')
  $bookBody = $book.find('.book-body')
  $bookPage = $book.find('.page-inner > .normal')
  $bookTitle = $book.find('.book-title')
  $bookProgressBar = $book.find('.book-progress .bar .inner')


  $toggleSummary.on 'click', (evt) ->
    if $book.hasClass('with-summary')
      $book.removeClass('with-search')
    $book.toggleClass('with-summary')
    evt.preventDefault()

  updateContributeUrl = (href) ->
    href = URI(href).relativeTo(URI(BookConfig.rootUrl + '/')).pathname()
    href = href.replace(/\.html$/, '.md')
    $bookSummary.find('.edit-contribute > a').attr('href', "#{BookConfig.contributeUrl}/#{href}")

  renderToc = ->
    $summary = $('<ul class="summary"></ul>')
    if BookConfig.issuesUrl
      $summary.append("<li class='issues'><a target='_blank' href='#{BookConfig.issuesUrl}'>Questions and Issues</a></li>")
    if BookConfig.contributeUrl
      $summary.append("<li class='edit-contribute'><a target='_blank' href='#{BookConfig.contributeUrl}'>Edit and Contribute</a></li>")
    $summary.append('<li class="divider"/>')
    $summary.append(tocHelper.$toc.children('li'))

    # Update the ToC to show which links have been visited
    # Add a "hidden" checkmark next to each item
    $summary.find('a[href]').parent().prepend('<i class="fa fa-check"></i>')
    for key of JSON.parse(window.localStorage.visited)
      $summary.find("li:has(> a[href='#{key}'])").addClass('visited')


    $bookSummary.children('.summary').remove()
    $bookSummary.append($summary)

    currentPagePath = URI(window.location.href).pathname()
    updateContributeUrl(currentPagePath)

  pageBeforeRender = ($els, href) ->
    updateContributeUrl(href)

    # Convert `img[title]` tags into figures so they get numbered and titles are visible
    for img in $els.find('img[title]')
      $img = $(img)
      id = $img.attr('id')
      $img.removeAttr('id')
      $figure = $img.wrap('<figure>').parent()
      $figure.append("<figcaption>#{$img.attr('title')}</figcaption>")
      $figure.prepend("<div data-type='title'>#{$img.attr('data-title')}</div>") if $img.attr('data-title')
      $figure.attr('id', id)


    # Remember that this page has been visited
    currentPagePath = URI(href).pathname()
    visited = window.localStorage.visited and JSON.parse(window.localStorage.visited) or {}
    visited[currentPagePath] = new Date()
    window.localStorage.visited = JSON.stringify(visited)



  tocHelper = new class TocHelper
    _tocHref: null
    _tocList: []
    _tocTitles: {}
    loadToc: (@_tocHref, @$toc, @$title) ->
      tocUrl = URI(BookConfig.toc.url).absoluteTo(window.location.href)

      @_tocTitles = {}
      @_tocList = for el in $toc.find('a[href]')
        href = URI(el.getAttribute('href')).absoluteTo(tocUrl).toString()
        @_tocTitles[href] = $(el).text()
        href

      # Fix up the ToC links if the server has trailing slashes
      if BookConfig.serverAddsTrailingSlash
        for a in @$toc.find('a')
          $a = $(a)
          href = $a.attr('href')
          href = '../' + href
          $a.attr('href', href)

      renderToc()

    # HACK. Should use URIJS to convert path relative to toc file
    _currentPageIndex: (currentHref) ->
      #currentHref = currentHref.substring(0, currentHref.length - 1)  if "/" is currentHref[currentHref.length - 1]
      @_tocList.indexOf(currentHref)

    prevPageHref: (currentHref) ->
      currentIndex = @_currentPageIndex(currentHref)
      @_tocList[currentIndex - 1] # returns undefined if no previous page

    nextPageHref: (currentHref) ->
      currentIndex = @_currentPageIndex(currentHref)
      @_tocList[currentIndex + 1] # returns undefined if no next page


  $.ajax(url: BookConfig.urlFixer(BookConfig.toc.url), headers: {'Accept': 'application/xhtml+xml'}, dataType: 'html')
  .then (html) ->
    $root = $('<div>' + html + '</div>')
    $toc = $root.find(BookConfig.toc.selector).first()
    if $toc[0].tagName.toLowerCase() is 'ul'
      # HACK for collection HTML
      $title = $toc.children().first().contents()
      $toc = $toc.find('ul').first()
    else
      $title = $root.children('title').contents()
    tocHelper.loadToc(BookConfig.toc.url, $toc, $title)
    $bookTitle.html(tocHelper.$title)


  # Fetch resources without fixing up their paths
  if BookConfig.baseHref
    $book.find('base').remove()
    $book.prepend("<base href='#{BookConfig.baseHref}'/>")

  $originalPage = $('<div class="contents"></div>').append($originalPage)
  pageBeforeRender($originalPage, URI(window.location.href).pathname())
  $bookPage.append($originalPage)

  changePage = (href) ->
    $book.addClass('loading')
    $.ajax(url: BookConfig.urlFixer(href), headers: {'Accept': 'application/xhtml+xml'}, dataType: 'html')
    .then (html) ->

      # Use `window.location.origin` to get around a <base href=""> pointing to another hostname
      unless /https?:\/\//.test(href)
        href = "#{window.location.origin}#{href}"
      window.history.pushState(null, null, href)

      # Need to set the URL *before* <img> tags area created
      # Fetch resources without fixing up their paths
      if BookConfig.baseHref
        $book.find('base').remove()
        $book.prepend("<base href='#{BookConfig.urlFixer(href)}'/>")


      $html = $("<div>#{html}</div>")
      $html.children('meta, link, script, title').remove()

      $bookPage.contents().remove()

      $page = $('<div class="contents"></div>').append($html.children())
      pageBeforeRender($page, href)
      $bookPage.append($page) # TODO: Strip out title and meta tags
      $book.removeClass('loading')
      # Scroll to top of page after loading
      $('.body-inner').scrollTop(0)



  # Listen to clicks and handle them without causing a page reload
  $('body').on 'click', 'a[href]:not([href^="#"]):not([href^="http"])', (evt) ->
    href = ($(@).attr('href'))
    href = URI(href).absoluteTo(URI(window.location.href)).toString()

    changePage(href)

    evt.preventDefault()
