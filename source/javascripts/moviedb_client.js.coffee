class MovieDBClient
  BASE_URL = "https://api.themoviedb.org/3/"
  BASE_IMAGE_URL = "http://image.tmdb.org/t/p/"

  constructor: (@apiKey) ->

  buildUrl: (path, options) ->
    "#{BASE_URL}#{path}?#{$.param($.extend(options, {api_key: @apiKey}))}"

  buildImageUrl: (path, size="w45") ->
    return null unless path
    "#{BASE_IMAGE_URL}#{size}#{path}"

  get: (path, options) ->
    $.ajax
      type: "get"
      dataType: "json"
      url: @buildUrl(path, options)

  movieCredits: (personId) ->
    @get "person/#{personId}/movie_credits", {}


window.MovieDBClient = MovieDBClient