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
        React.PropTypes.shape({
          name: React.PropTypes.string.isRequired,
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
        models = _.filter(items, (i) => i.props.item.type == _jed('Model'))
        options = _.filter(items, (i) => i.props.item.type == _jed('Option'))
        templates = _.filter(items, (i) => i.props.item.type == _jed('Template'))

        return (
          <div className='' style={{...style, ...this.menuStyle}}>
            <ul className='dropdown-menu'>
              {(() => {
                  if (models.length !== 0) {
                    return (
                      <div>
                        <li className='disabled'><b>{_jed('Models')}</b></li>
                        <ul className='dropdown-menu scroll-menu scroll-menu-2x'>{models}</ul>
                      </div>
                    )
                  }
              })()}
              {(() => {
                  if (options.length !== 0) {
                    return (
                      <div>
                        <li className='disabled'><b>{_jed('Options')}</b></li>
                        <ul className='dropdown-menu scroll-menu scroll-menu-2x'>{options}</ul>
                      </div>
                    )
                  }
              })()}
              {(() => {
                  if (templates.length !== 0) {
                    return (
                      <div>
                        <li className='disabled'><b>{_jed('Templates')}</b></li>
                        <ul className='dropdown-menu scroll-menu scroll-menu-2x'>{templates}</ul>
                      </div>
                    )
                  }
              })()}
            </ul>
          </div>
        )
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
                  item={item}
                  id={item.abbr}
                  style={isHighlighted ? styles.highlightedItem : styles.item}
                  tabIndex='-1'
                  className='separated-bottom exclude-last-child ui-menu-item'>
                  <a className='row light-red' title={item.name}>
                    <div className='row'>
                      <div className='col3of4' title={item.name}>
                        <strong className='wrap'>{item.name}</strong>
                      </div>
                      <div className='col1of4 text-align-right'>
                        <div className='row'>{item.availability}</div>
                        <div className='row'>
                          <span className='grey-text'>{item.type}</span>
                        </div>
                      </div>
                    </div>
                  </a>
                </li>
              ) }}
            />

        </div>
      )
    }
  })
})()
