class window.App.ReservationAssignOrCreateController extends Spine.Controller

  elements:
    "#add-start-date": "addStartDate"
    "#add-end-date": "addEndDate"

  events:
    "submit": "submit"

  constructor: ->
    super

    that = @

    new App.SwapModelController {el: @el}

    reservationsAddController = new App.ReservationsAddController
      el: @el
      user: @user
      status: @status
      contract: @contract
      optionsEnabled: true

    # create and mount the input field:
    props =
      onChange: (value)->
        # TODO: _.debounce(searchFn, 300)
        reservationsAddController.search value, (data)->
          console.log 'searchResults', data, (try _.get(data[0].record))
          that.autocompleteController.setSearchResults(data)
          that.autocompleteController._render()
          # that.autocompleteController.setProps(searchResults: data)
          # console.log @autocompleteController.props
      onSelect: (item)-> console.log 'Select!', item
      isLoading: false
      placeholder: _jed("Inventory code, model name, search term")

    @autocompleteController =
      new App.HandOverAutocompleteController \
        props,
        @el.find("#assign-or-add-input")[0]

    @autocompleteController._render()

    window.autocompleteController = @autocompleteController

    reservationsAddController.setupAutocomplete(@autocompleteController)

  getStartDate: => moment(@addStartDate.val(), i18n.date.L)

  getEndDate: => moment(@addEndDate.val(), i18n.date.L)

  submit: (e)=>
    e.preventDefault()
    e.stopImmediatePropagation()
    inventoryCode = @input.val() # TODO
    return false unless inventoryCode.length
    App.Reservation.assignOrCreate
      start_date: @getStartDate().format("YYYY-MM-DD")
      end_date: @getEndDate().format("YYYY-MM-DD")
      code: inventoryCode
      contract_id: @contract.id
    .done((data) => @assignedOrCreated inventoryCode, data)
    .error (e)=>
      App.Flash
        type: "error"
        message: e.responseText
    @input.val("") # TODO

  assignedOrCreated: (inventoryCode, data)=>
    done = =>
      if App.Reservation.exists(data.id) # assigned
        line = App.Reservation.update data.id, data
        if line.model_id?
          App.Flash
            type: "success"
            message: _jed "%s assigned to %s", [inventoryCode, line.model().name()]
        else if line.option_id?
          App.Flash
            type: "notice"
            message: _jed("%s quantity increased to %s", [line.option().name(), line.quantity])
      else # created
        line = App.Reservation.addRecord new App.Reservation(data)
        App.Contract.trigger "refresh", @contract
        App.Flash
          type: "success"
          message: _jed("Added %s", line.model().name())
      App.LineSelectionController.add line.id

    if data.model_id?
      App.Item.ajaxFetch
        data: $.param
          ids: [data.item_id]
      .done =>
        App.Model.ajaxFetch
          data: $.param
            ids: [data.model_id]
        .done(done)
    else if data.option_id?
      App.Option.ajaxFetch
        data: $.param
          ids: [data.option_id]
      .done(done)
