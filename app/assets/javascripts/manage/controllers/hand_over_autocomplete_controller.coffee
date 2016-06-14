class window.App.HandOverAutocompleteController

  constructor: (@props, @container) ->

  _render: ->
    ReactDOM.render \
      React.createElement(HandoverAutocomplete, @props),
      @container

  setSearchResults: (results) -> @props['searchResults'] = results

  # setProps: (newProps) ->
  #   @props = _.extend(@props, newProps)
  #   @_render()
