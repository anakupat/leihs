class window.App.HandOverAutocompleteController

  constructor: (@props, @container) ->

  _render: ->
    ReactDOM.render \
      React.createElement(HandoverAutocomplete, @props),
      @container

  renderWith: (results) ->
    @setSearchResults(results)
    @_render()

  setSearchResults: (results) -> @props['searchResults'] = results

  # setProps: (newProps) ->
  #   @props = _.extend(@props, newProps)
  #   @_render()
