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
  ]

  constructor: ->
    # Create a MovieDB client'
    @client = new MovieDBClient("8f564a315e6d6e0079d1024f7428f9cf")

    # Attach typeahead functionality to actor inputs
    $("[data-actor]").typeahead 
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
    $("[data-actor]").on "typeahead:selected", (e, actor) ->
      $(this).data "actor-id", actor.id

    # Fix bootstrap styles with typeahead
    $('.tt-hint').addClass('form-control')

    # Fill in some sample searches
    @randomize()

    # Hook up clear button
    $("#reset").click (e) =>
      @reset()
      e.preventDefault()

    # Hook up form submit
    $("form").submit (e) =>
      @search()
      e.preventDefault()

  randomize: ->
    SAMPLE_SEARCHES.sort(-> 0.5 - Math.random())

    $("[data-actor]").each (idx) ->
      actor = SAMPLE_SEARCHES[idx]
      $(this)
        .val(actor.name)
        .data("actor-id", actor.id)

  randomSearch: ->
    @randomize()
    @search()

  search: ->
    # TODO: Validate form fields are filled

    $("form").fadeOut => $("#loading").fadeIn =>
      # Fetch actor ids from inputs
      actorIds = $("[data-actor]").map(-> $(this).data("actor-id")).toArray()

      # Create credits promises for each actor
      actorCredits = actorIds.map (id) => @client.movieCredits(id)

      # Find shared credits
      Q.all(actorCredits).then (data) =>
        sharedCredits = data[0].cast.filter (credit) ->
          data[1].cast.some (el) -> credit.id == el.id

        # Show the results
        $("#movies").empty()

        actorNames = $.map($("[data-actor]"), (el) -> $(el).val()).join(" &amp; ")
        if sharedCredits.length > 0
          movies = if sharedCredits.length > 1 then "movies" else "movie"
          $("#results h2").html("Yes! #{actorNames} have starred in #{sharedCredits.length} #{movies} together!")

          sharedCredits.forEach (credit) =>
            $("#movies").append RESULTS_TEMPLATE.render({
              name: credit.title,
              image: @client.buildImageUrl(credit.poster_path)
            })
        else
          $("#results h2").html("No! #{actorNames} have never starred together!")

        $("#loading").fadeOut ->
          $("#results").fadeIn()

      , (xhr) ->
        console.log "failed", xhr

  reset: ->
    $("[data-actor]")
      .val("")
      .data("actor-id", null)

    $("#movies").empty()
    $("#results").fadeOut -> $("form").fadeIn ->
      $("[data-actor]:first").focus()


new StarredTogether()