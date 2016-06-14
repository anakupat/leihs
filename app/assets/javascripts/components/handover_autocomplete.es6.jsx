(() => {
  // NOTE: only for linter and clarity:
  const React = window.React
  const ReactDOM = window.ReactDOM
  const Autocomplete = window.ReactAutocomplete
  React.findDOMNode = ReactDOM.findDOMNode // NOTE: autocomplete lib needs this

  // TMP: styling from library example
  const styles = {
    item: {
      padding: '2px 6px',
      cursor: 'default'
    },
    highlightedItem: {
      color: 'white',
      background: 'hsl(200, 50%, 50%)',
      padding: '2px 6px',
      cursor: 'default'
    },
    menu: {
      border: 'solid 1px #ccc'
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
          availability: React.PropTypes.string.isRequired,
          type: React.PropTypes.string.isRequired,
          record: React.PropTypes.objectOf({
            cid: React.PropTypes.string.isRequired
          }).isRequired
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

      return (
        <div>

        <Autocomplete
          ref='autocomplete'
          value={this.state.value}
          items={props.searchResults}
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
              <div
                style={isHighlighted ? styles.highlightedItem : styles.item}
                key={item.type + item.record.cid}
                id={item.abbr}>{item.name}</div>
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
