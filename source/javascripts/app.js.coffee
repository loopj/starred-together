class StarredTogether
  # Templates
  TYPEAHEAD_TEMPLATE = """
    <img src="{{image}}">
    <span>{{name}}</span>
    """

  RESULTS_TEMPLATE = Hogan.compile """
    <li>
      <img src="{{image}}">
      <span>{{name}}</span>
    </li>
    """

  SAMPLE_SEARCHES = [
    {name: "Jennifer Lawrence", id: 72129}
    {name: "Patrick Stewart", id: 2387}
    {name: "Ian McKellen", id: 1327}
    {name: "Kevin Bacon", id: 4724}
    {name: "Christian Bale", id: 3894}
    {name: "Leonardo DiCaprio", id: 6193}
    {name: "Amy Adams", id: 9273}
    {name: "Cate Blanchett", id: 112}
    {name: "Sandra Bullock", id: 18277}
    {name: "Meryl Streep", id: 5064}
  ]

  shuffleArray = (a) ->
    i = a.length
    while --i > 0
      j = ~~(Math.random() * (i + 1))
      t = a[j]; a[j] = a[i]; a[i] = t
    a

  constructor: ->
    # Create a MovieDB client'
    @client = new MovieDBClient("8f564a315e6d6e0079d1024f7428f9cf")

    # Cache some jquery selectors
    @actorInputs = $("[data-actor]")
    @form = $("form")
    @movieList = $("#movies")
    @loadingSpinner = $("#loading")
    @resultsTitle = $("#results h2")
    @resultsPane = $("#results")

    # Attach typeahead functionality to actor inputs
    @actorInputs.typeahead 
      template: TYPEAHEAD_TEMPLATE,
      engine: Hogan,
      name: "actors",
      remote:
        url: @client.buildUrl("search/person", {search_type: "ngram"}) + "&query=%QUERY",
        filter: (response) =>
          response.results.map (result) =>
            id: result.id
            name: result.name
            image: @client.buildImageUrl(result.profile_path)
            value: result.name

    # Store selected actor id on input
    @actorInputs.on "typeahead:selected", (e, actor) ->
      $(this).data "actor-id", actor.id

    # Fix bootstrap styles with typeahead
    $('.tt-hint').addClass('form-control')

    # Fill in some sample searches
    @randomize()

    # Hook up clear button
    $("#reset").click (e) =>
      @reset =>
        @actorInputs.first().focus()

      e.preventDefault()

    $("#random").click (e) =>
      @randomSearch()
      e.preventDefault()

    # Hook up form submit
    @form.submit (e) =>
      @search()
      e.stopPropagation()
      e.preventDefault()

  randomize: ->
    shuffleArray(SAMPLE_SEARCHES)
    @actorInputs.each (idx) ->
      actor = SAMPLE_SEARCHES[idx]
      $(this)
        .val(actor.name)
        .data("actor-id", actor.id)

  randomSearch: ->
    @reset()
    @randomize()

  search: ->
    # TODO: Validate form fields are filled

    @form.fadeOut => @loadingSpinner.fadeIn =>
      # Fetch actor ids from inputs
      actorIds = @actorInputs.map(-> $(this).data("actor-id")).toArray()

      # Create credits promises for each actor
      actorCredits = actorIds.map (id) => @client.movieCredits(id)

      # Find shared credits
      Q.all(actorCredits).then (data) =>
        sharedCredits = data[0].cast.filter (credit) ->
          data[1].cast.some (el) -> credit.id == el.id

        # Show the results
        @movieList.empty().show()

        actorNames = $.map(@actorInputs, (el) -> $(el).val()).join(" & ")
        if sharedCredits.length > 0
          movies = if sharedCredits.length > 1 then "movies" else "movie"
          @resultsTitle.text("Yes! #{actorNames} have starred in #{sharedCredits.length} #{movies} together!")

          sharedCredits.forEach (credit) =>
            @movieList.append RESULTS_TEMPLATE.render({
              name: credit.title,
              image: @client.buildImageUrl(credit.poster_path)
            })
        else
          @movieList.hide()
          @resultsTitle.text("No! #{actorNames} have never starred together!")

        @loadingSpinner.fadeOut => @resultsPane.fadeIn()

      , (xhr) ->
        console.log "failed", xhr

  reset: (cb) ->
    @actorInputs
      .val("")
      .data("actor-id", null)

    @resultsPane.fadeOut => @form.fadeIn =>
      @movieList.empty()
      cb() if cb


new StarredTogether()