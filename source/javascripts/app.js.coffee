class StarredTogether
  # Templates
  TYPEAHEAD_TEMPLATE = """
    <img src="{{image}}">
    {{name}}
    """

  RESULTS_TEMPLATE = Hogan.compile """
    <img src="{{image}}">
    {{name}}
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
    $("#clear").click (e) =>
      @clear()
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
    # Fetch actor ids from inputs
    actorIds = $("[data-actor]").map(-> $(this).data("actor-id")).toArray()
    console.log actorIds

    # Create credits promises for each actor
    actorCredits = actorIds.map (id) => @client.movieCredits(id)

    # Find shared credits
    Q.all(actorCredits).then (data) =>
      sharedCredits = data[0].cast.filter (credit) ->
        data[1].cast.some (el) -> credit.id == el.id

      # Show the results
      $("#movies").empty()

      if sharedCredits.length > 0
        $("#result").html("YES")

        sharedCredits.forEach (credit) =>
          $("#movies").append RESULTS_TEMPLATE.render({
            name: credit.title,
            image: @client.buildImageUrl(credit.poster_path)
          })
      else
        $("#result").html("NO")

    , (xhr) ->
      console.log "failed"

  clear: ->
    $("[data-actor]")
      .val("")
      .data("actor-id", null)

    $("#movies").empty()
    $("#result").empty()

    $("[data-actor]:first").focus()

new StarredTogether()