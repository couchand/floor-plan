# floor plan

throttle = (fn) ->
  _.throttle fn, 10

{
  div, label, input, button, ul, li, a
  svg, g, path, circle, rect, text
} = React.DOM

margin =
  left: 10
  top: 10
  right: 10
  bottom: 10

scaleFt = (d) ->
  d * 0.03281

scaleFt.invert = (d) ->
  d / 0.03281

report = _.throttle ((e)-> alert e.message), 1000

row = React.createClass
  handleUpdate: (event) ->
    field = items.child @props.id
      .child @props.field
    field.set if @props.type is "checkbox"
      event.target.checked
    else
      event.target.value or 0
  render: ->
    field =
      type: @props.type
      onChange: @handleUpdate
    if @props.type is "checkbox"
      field.checked = @props.item?[@props.field] or false
    else
      field.value = @props.item?[@props.field] or ""
    div
      className: "row"
      label null,
        @props.label or @props.field
        input field

details = React.createClass
  render: ->
    id = @props.id
    item = @props.item
    div
      className: "details"
      row {id, item, field: "name", type: "text"}
      row {id, item, field: "color", type: "text"}
      row {id, item, field: "fixed", type: "checkbox"}
      row {id, item, field: "a", label: "angle", type: "text"}
      row {id, item, field: "x", type: "text"}
      row {id, item, field: "y", type: "text"}
      row {id, item, field: "z", type: "text"}

entities = React.createClass
  handleClick: (id) ->
    (event) =>
      @props.onSelect id
      event.preventDefault()
  render: ->
    ul
      className: "items"
      [0...@props.items.length].map (id) =>
        item = @props.items[id]
        li
          key: id
          a
            href: "#"
            onClick: @handleClick(id)
            item.name

line = React.createClass
  componentDidMount: ->
    return if @props.item.fixed
    extract = (d) => Math.round @props.scale.invert d
    drag = d3.behavior.drag()
      .on "drag", throttle ->
        item = items.child d3.select(this).datum()
        item.update
          x: extract d3.event.x
          y: extract d3.event.y
          (err) -> report err if err
    d3.select @refs.path.getDOMNode()
      .datum @props.id
      .call drag
  handleMouseOver: ->
    @props.onMouseOver()
  handleMouseOut: ->
    @props.onMouseOut()
  render: ->
    me = @props.item
    scaled = me.points.map (p) => p.map @props.scale
    x = @props.scale me.x or 0
    y = @props.scale me.y or 0
    angle = me.a or 0
    g
      ref: "path"
      className: "item"
      transform: "translate(#{x},#{y})rotate(#{angle})"
      onMouseOver: @props.onMouseOver
      onMouseOut: @props.onMouseOut
      onClick: @props.onClick
      circle
        cx: 0
        cy: 0
        r: 5
        fill: if @props.item.fixed then "none" else if @props.selected then "blue" else "grey"
      path
        d: "M#{scaled.map((p) -> p.join ',').join 'L'}Z"
        stroke: me.color or "black"
        "data-id": @props.id

grid = React.createClass
  render: ->
    max = Math.ceil scaleFt @props.scale.invert Math.max @props.dims.width, @props.dims.height
    ticks = [0..max].map scaleFt.invert
    g
      className: "grid"
      for tick in ticks
        path
          d: "M#{@props.scale tick},0V#{@props.focus.height}"
          stroke: "#CCC"
      for tick in ticks
        path
          d: "M0,#{@props.scale tick}H#{@props.focus.width}"
          stroke: "#CCC"

tip = React.createClass
  render: ->
    x = if @props.tip isnt "" then @props.scale @props.mouseX else -999
    y = if @props.tip isnt "" then @props.scale @props.mouseY else -999
    text
      className: "tooltip"
      transform: "translate(#{x-6},#{y-6})"
      @props.tip

app = React.createClass
  getInitialState: ->
    dims: dims =
      width: window.innerWidth or 500
      height: window.innerHeight or 500
    focus: focus =
      width: dims.width - margin.left - margin.right
      height: dims.height - margin.top - margin.bottom
    scale: d3.scale.linear()
      .range [0, Math.min focus.width, focus.height]
      .domain [0, 1000]
    margin: margin
    mouseX: 0
    mouseY: 0
    tip: ""
    selected: no
    doc: doc
  componentDidMount: ->
    window.onresize = =>
      dims =
        width: window.innerWidth or 500
        height: window.innerHeight or 500
      focus =
        width: dims.width - margin.left - margin.right
        height: dims.height - margin.top - margin.bottom
      scale = d3.scale.linear()
        .range [0, Math.min focus.width, focus.height]
        .domain [0, 1000]
      @setState {dims, focus, scale}
    d3.select @refs.main.getDOMNode()
      .on "mousemove", =>
        mouseX = @state.scale.invert d3.event.clientX - margin.left
        mouseY = @state.scale.invert d3.event.clientY - margin.top
        @setState {mouseX, mouseY}
  fork: ->
    child = root.child name = @refs.name.getDOMNode().value
    child.update {items: @props.items}, (err) ->
      console.log arguments
      if err
        report err
      else
        window.location.hash = "##{name}"
  render: ->
    cmx = Math.round @state.mouseX
    cmy = Math.round @state.mouseY
    ftx = Math.round(10 * scaleFt @state.mouseX)/10
    fty = Math.round(10 * scaleFt @state.mouseY)/10
    order = [0...@props.items.length].sort (a, b) =>
      x = @props.items[a].z or 0
      y = @props.items[b].z or 0
      if x < y then -1 else if x > y then 1 else 0
    div null,
      svg
        width: @state.dims.width
        height: @state.dims.height
        g
          transform: "translate(#{margin.left},#{margin.top})"
          ref: "main"
          rect
            width: @state.dims.width
            height: @state.dims.height
            fill: "white"
          grid
            dims: @state.dims
            focus: @state.focus
            scale: @state.scale
          order.map (id) =>
            item = @props.items[id]
            onMouseOver = =>
              @setState tip: item.name
            onMouseOut = =>
              @setState tip: ""
            onClick = =>
              @setState selected: id
            selected = id is @state.selected
            line {
              id, item, selected, scale: @state.scale
              onMouseOver, onMouseOut, onClick
            }
          tip @state
      div null,
        input
          ref: "name"
          className: "layoutName"
          defaultValue: @state.doc
        button
          className: "fork"
          onClick: @fork
          "fork this layout"
      div
        className: "status"
        "#{cmx}cm, #{cmy}cm - #{ftx}ft, #{fty}ft"
      entities
        items: @props.items
        onSelect: (id) =>
          @setState selected: id
      details
        id: @state.selected
        item: @props.items[@state.selected]

root = new Firebase "https://blazing-fire-9139.firebaseio.com/"

fb = items = doc = no
loadFB = ->
  doc = window.location.hash[1..] or "1"
  fb = root.child(doc)
  items = fb.child("items")

  fb.on "value", (d) ->
    React.renderComponent app(d.val()),
      document.getElementById "app"

window.addEventListener "hashchange", loadFB

loadFB()
