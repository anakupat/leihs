(() => {
  // NOTE: only for linter and clarity:
  const React = window.React
  const ReactDOM = window.ReactDOM
  const Autocomplete = window.ReactAutocomplete
  React.findDOMNode = ReactDOM.findDOMNode // NOTE: autocomplete lib needs this

  // TMP: styling from library example
  const styles = {
    item: { // item/line default styles
      padding: '2px 6px',
      cursor: 'default'
    },
    highlightedItem: { // when item is selected in list (e.g. hovered)
      color: 'white',
      background: 'hsl(200, 50%, 50%)',
      padding: '2px 6px',
      cursor: 'default'
    }
  }

  window.HandoverAutocomplete = React.createClass({
    propTypes: {
      placeholder: React.PropTypes.string.isRequired,
      onChange: React.PropTypes.func.isRequired,
      onSelect: React.PropTypes.func.isRequired,
      isLoading: React.PropTypes.bool.isRequired,
      searchResults: React.PropTypes.arrayOf(
        React.PropTypes.objectOf({
          label: React.PropTypes.string.isRequired,
          availability: React.PropTypes.string,
          type: React.PropTypes.string.isRequired,
          record: React.PropTypes.object.isRequired
        })
      )
    },

    getDefaultProps: function () {
      return { searchResults: [] }
    },

    getInitialState: function () {
      return { value: '' }
    },

    _handleChange: function (event, value) {
      // update internal state to reflect new input:
      this.setState({ value: value })
      // callback to controller:
      this.props.onChange(value)
    },

    // public methods
    val: function () { // setter and getter!
      return 'TODO return val'
    },

    render: function () {
      const props = this.props

      // TODO: barcode-scanner-target??? (if needed, put in inputProps)
      // TODO: id='assign-or-add-input'???

      var inputProps = {
        type: 'text',
        className: 'row',
        placeholder: props.placeholder
      }

      var wrapperProps = {
        style: {}
      }

      var renderMenu = function (items, value, style) {
        if (items.length === 0) { return <div/> }
        return (
          <div style={{...style, ...this.menuStyle}} children={items}/>
        )
        // return (
          // <div style={{...style, ...this.menuStyle}}>
            // <ul class='dropdown-menu'>
              // <li class='disabled'><b>{_jed('Models')}</b></li>
              // <li>
                // <ul class='dropdown-menu scroll-menu scroll-menu-2x'>
                // </ul>
              // <li class='disabled'><b>{_jed('Options')}</b></li>
              // <li class='disabled'><b>{_jed('Templates')}</b></li>
            // </ul>
          // </div>
        // )
      }

      return (
        <div>

          <Autocomplete
            ref='autocomplete'
            value={this.state.value}
            items={props.searchResults}
            wrapperProps={wrapperProps}
            inputProps={inputProps}
            renderMenu={renderMenu}
            getItemValue={(item) => item.name}
            onSelect={(value, item) => {
              // reset the input field
              this.setState({ value: '' })
              // callback
              props.onSelect(item)
            }}
            onChange={this._handleChange}
            renderItem={(item, isHighlighted) => {
              return (
                <li
                  key={item.type + item.name + item.record.cid}
                  id={item.abbr}
                  style={isHighlighted ? styles.highlightedItem : styles.item}
                  tabindex="-1" id="ui-id-2" class="separated-bottom exclude-last-child ui-menu-item">
                  <a class="row light-red" title={item.name}>
                    <div class="row">
                      <div class="col3of4" title={item.name}>
                        <strong class="wrap">{item.name}</strong>
                      </div>
                      <div class="col1of4 text-align-right">
                        <div class="row">{item.availability}</div>
                        <div class="row">
                          <span class="grey-text">{item.type}</span>
                        </div>
                      </div>
                    </div>
                  </a>
                </li>
              )}}
            />

        </div>
      )
    }
  })

  /*
    <input
    type='text'
    className='row'
    name='input'
    placeholder={props.placeholder}
    autoComplete='off'
    onChange={props.onSearch}
    data-barcode-scanner-target/>
  */
})()
