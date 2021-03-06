# floor plan

throttle = (fn) ->
  _.throttle fn, 10

{
  div, label, input, button, ul, li, a
  svg, g, path, circle, rect, text
} = React.DOM

KEY_UP = 38
KEY_DN = 40

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
    return unless @props.id
    field = items.child @props.id
      .child @props.field
    field.set if @props.type is "checkbox"
      event.target.checked
    else
      event.target.value or 0
  handleKeyPress: (event) ->
    return unless @props.type is "number" and
      @props.id and
      event.keyCode in [KEY_UP, KEY_DN]
    newVal = +event.target.value
    newVal += switch event.keyCode
      when KEY_UP
        1
      when KEY_DN
        -1
      else 0
    event.target.value = newVal
    @handleUpdate event
  render: ->
    field =
      type: if @props.type is "number" then "text" else @props.type
      onChange: @handleUpdate
      onKeyPress: @handleKeyPress
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
      row {id, item, field: "a", label: "angle", type: "number"}
      row {id, item, field: "x", type: "number"}
      row {id, item, field: "y", type: "number"}
      row {id, item, field: "z", type: "number"}

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
    color = if @props.item.fixed
      "none"
    else if @props.selected
      "blue"
    else
      "grey"
    g
      ref: "path"
      className: "item"
      transform: "translate(#{x},#{y})rotate(#{angle})"
      onMouseOver: @props.onMouseOver
      onMouseOut: @props.onMouseOut
      onClick: @props.onClick
      circle
        className: "handle"
        cx: 0
        cy: 0
        r: 5
        fill: color
      path
        d: "M#{scaled.map((p) -> p.join ',').join 'L'}Z"
        stroke: me.color or "black"
        "data-id": @props.id

grid = React.createClass
  render: ->
    max = Math.max @props.width, @props.height
    max = Math.ceil scaleFt @props.scale.invert max
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
    unless @props.tip
      x = y = -999
    else
      x = @props.clientX
      y = @props.clientY
    text
      className: "tooltip"
      transform: "translate(#{x-6},#{y-6})"
      @props.tip

chart = React.createClass
  getInitialState: ->
    clientX: 0
    clientY: 0
    tip: ""
  getDefaultProps: ->
    onMouseMove: ->
  componentDidMount: ->
    {scale} = @getScale()
    d3.select @refs.main.getDOMNode()
      .on "mousemove", =>
        clientX = d3.event.clientX - margin.left
        clientY = d3.event.clientY - margin.top
        mouseX = scale.invert clientX
        mouseY = scale.invert clientY
        @setState {clientX, clientY}
        @props.onMouseMove {mouseX, mouseY}
  getScale: ->
    focus: focus =
      width: @props.width - @props.margin.left - @props.margin.right
      height: @props.height - @props.margin.top - @props.margin.bottom
    scale: d3.scale.linear()
      .range [0, Math.min focus.width, focus.height]
      .domain [0, 1000]
  render: ->
    {focus, scale} = @getScale()
    order = [0...@props.items.length].sort (a, b) =>
      x = @props.items[a].z or 0
      y = @props.items[b].z or 0
      if x < y then -1 else if x > y then 1 else 0
    svg
      width: @props.width
      height: @props.height
      g
        transform: "translate(#{margin.left},#{margin.top})"
        ref: "main"
        rect
          width: @props.width
          height: @props.height
          fill: "white"
        if @props.grid
          grid
            width: @props.width
            height: @props.height
            focus: focus
            scale: scale
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
            id, item, selected, scale
            onMouseOver, onMouseOut, onClick
          }
        if @props.tip
          tip
            tip: @state.tip
            clientX: @state.clientX
            clientY: @state.clientY

app = React.createClass
  getInitialState: ->
    dims: dims =
      width: window.innerWidth or 500
      height: window.innerHeight or 500
    margin: margin
    mouseX: 0
    mouseY: 0
    selected: no
  componentDidMount: ->
    window.onresize = =>
      {dims} = @getInitialState()
      @setState {dims}
  handleMouseMove: (coords) ->
    @setState coords
  handleNameChange: ->
    name = fb.child "name"
    name.set event.target.value
  fork: ->
    newRef = root.push()
    newRef.update {items: @props.items}, (err) ->
      if err
        report err
      else
        window.location.hash = "##{newRef.name()}"
  render: ->
    cmx = Math.round @state.mouseX
    cmy = Math.round @state.mouseY
    ftx = scaleFt(@state.mouseX).toFixed 1
    fty = scaleFt(@state.mouseY).toFixed 1
    div null,
      chart
        width: @state.dims.width
        height: @state.dims.height
        margin: @state.margin
        items: @props.items
        onMouseMove: @handleMouseMove
        grid: yes
        tip: yes
      div null,
        a
          href: "#"
          className: "indexLink"
          "index"
        input
          className: "layoutName"
          onChange: @handleNameChange
          placeholder: "name this layout..."
          value: @props.name
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

index = React.createClass
  render: ->
    div
      className: "index"
      for name, layout of @props.layouts
        indexEntry
          key: name
          name: name
          items: layout.items
          label: layout.name

indexEntry = React.createClass
  render: ->
    a
      href: "##{@props.name}"
      className: "layout"
      chart
        width: 180
        height: 180
        margin:
          left: 2
          top: 2
          right: 2
          bottom: 2
        items: @props.items
      div
        className: "name"
        @props.label

root = new Firebase "https://blazing-fire-9139.firebaseio.com/"

fb = items = no
renderDoc = (doc="1") ->
  fb = root.child(doc)
  items = fb.child("items")

  fb.on "value", (d) ->
    React.renderComponent app(_.extend {}, d.val(), {doc}),
      document.getElementById "app"

renderIndex = ->
  root.once "value", (d) ->
    React.renderComponent index(layouts: d.val()),
      document.getElementById "app"

loadFB = ->
  doc = window.location.hash[1..]
  if doc
    renderDoc doc
  else
    renderIndex()

window.addEventListener "hashchange", loadFB

loadFB()
