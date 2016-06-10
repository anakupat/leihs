React = window.React

window.HandoverAutocomplete = React.createClass({
  propTypes: {
    placeholder: React.PropTypes.string.isRequired,
    onSearch: React.PropTypes.func.isRequired,
    onSelect: React.PropTypes.func.isRequired,
    isSearching: React.PropTypes.bool.isRequired,
    searchResults: React.PropTypes.arrayOf(
      React.PropTypes.objectOf({
        label: React.PropTypes.string.isRequired,
        availability: React.PropTypes.string.isRequired,
        record: React.PropTypes.object.isRequired
      })
    )
  },

  render: function() {
    return (
      <div>
        <div>Placeholder: {this.props.placeholder}</div>
        <div>On Search: {this.props.onSearch}</div>
        <div>On Select: {this.props.onSelect}</div>
      </div>
    )
  }
})
