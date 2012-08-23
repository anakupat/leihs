###

  Line

  This script provides functionalities for the generic Line
  
###

class Line
  
  @remove = (options)->
    $(options.element).trigger('before_remove_line', [options])
    # animate and remove    
    $(options.element).css("background-color", options.color).fadeOut 400, ()->
      list = $(this).closest(".list")
      # remove line groups or visits completely if line was the element
      if $(this).closest(".linegroup").find(".lines .line").length == 1
        if $(this).closest(".visit").find(".line").length == 1
          $(this).closest(".visit").remove()
        else
          $(this).closest(".indent").next("hr").remove()
          $(this).closest(".indent").remove()
      else
        $(this).remove()    
      options.callback() if options.callback? 
      $(document).trigger('after_remove_line', [options])
      List.update list if list?
      
  @get_problems = (data)->
    problems = []
    if moment(data.start_date).eod().diff(moment().eod(), "days") < 0 and moment(data.end_date).eod().diff(moment().eod(), "days") < 0
      problems.push
        type: "overdue"
        days_overdue: Math.abs moment(data.end_date).diff(moment().eod(), "days")
    else if data.is_available == false and data.availability_for_inventory_pool?
      av = new App.Availability(data.availability_for_inventory_pool.availability)
      groupIds = _.map Line.get_user(data).groups, (g)-> g.id
      problems.push 
        type: "availability"
        total_borrowable: data.total_borrowable
        total_rentable: data.total_rentable
        max_available_for_borrower: av.maxAvailableForGroups moment(data.start_date).toDate(), moment(data.end_date).toDate(), groupIds
        max_available_in_total: av.maxAvailableInTotal moment(data.start_date).toDate(), moment(data.end_date).toDate()
    if data.item? and data.item.is_borrowable? and data.item.is_borrowable == false
      problems.push
        type: "unborrowable"
    if data.item? and data.item.is_broken? and data.item.is_broken == true
      problems.push
        type: "broken"
    if data.item? and data.item.is_incomplete? and data.item.is_incomplete == true
      problems.push
        type: "incomplete"
    return problems
  
  @highlight = (line_element, type)->
    $(line_element).addClass("highlight #{type}")
    setTimeout ()->
      $(line_element).removeClass("highlight #{type}")
    , 300
    
  @recompute_availability = (line_data)->
    availability = line_data.availability_for_inventory_pool.availability
    line_type = Underscore.str.classify(line_data.type)
    line_data.is_available = true
    for change in availability
      break if line_data.is_available == false
      allocations = change[2]
      for allocation in allocations
        if allocation.out_document_lines[line_type]? and (allocation.out_document_lines[line_type].indexOf(line_data.id) > -1) and (allocation.in_quantity < 0)
          line_data.is_available = false
          break

  @remove_line_from_availability = (line_data, availability)->
    return undefined if not availability?
    line_type = Underscore.str.classify(line_data.type)
    for change in availability
      allocations = change[2]
      for allocation in allocations
        if allocation.out_document_lines? and allocation.out_document_lines[line_type]? and (allocation.out_document_lines[line_type].indexOf(line_data.id) > -1)
          allocation.out_document_lines[line_type] = _.filter allocation.out_document_lines[line_type], (line)-> line != line_data.id
          allocation.in_quantity += line_data.quantity
          change[1] += line_data.quantity
    availability
    
  @get_user: (lines_data)->
    return lines_data.order.user if lines_data.order? and lines_data.order.user?
    return lines_data.contract.user if lines_data.contract? and lines_data.contract.user?
    return lines_data.user
    
  @concatinate_purposes: (lines_data)->
    _map = _.map lines_data, (line)-> line.purpose
    _compact = _.compact _map
    _uniq = _.uniq _compact, false, (purpose)-> purpose.id
    _final = _.map _uniq, (purpose)-> purpose.description
    _final.join('; ')
 
  @prepare_for_handover: (lines, date)->
    _.each lines, (line)->
      # set start date to today
      line.start_date = moment().format("YYYY-MM-DD")
      # set end date to today if end date is in history
      if moment(line.end_date).eod().diff(moment().eod(), "days") < 0
        line.end_date = moment().format("YYYY-MM-DD")
    lines
    
  @get_returned: (lines)->
    _.filter lines, (line)-> line.returned_date?
    
  @get_not_returned: (lines)->
    _.filter lines, (line)-> not line.returned_date?
    
  @extend_with_consecutive_numbers: (lines)->
    last_total = 0
    _.each lines, (line)->
      line.consecutive_numbers = {}
      line.consecutive_numbers.from = last_total + 1
      last_total += line.quantity
      line.consecutive_numbers.to = last_total if last_total > line.consecutive_numbers.from
    lines
    
  @is_start_date_moveable: (line)-> if line.order? then true else line.contract.action != "take_back"

window.Line = Line