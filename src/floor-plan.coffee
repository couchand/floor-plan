# floor plan

throttle = (fn) ->
  _.throttle fn, 10

fb = new Firebase "https://blazing-fire-9139.firebaseio.com/"
items = fb.child("items")

{div, svg, g, path, circle, rect, text} = React.DOM

chart =
  width: 500
  height: 500

margin =
  left: 10
  top: 10
  right: 10
  bottom: 10

focus =
  width: chart.width - margin.left - margin.right
  height: chart.height - margin.top - margin.bottom

scale = d3.scale.linear()
  .range [0, Math.min focus.width, focus.height]
  .domain [0, 1000]

scaleFt = (d) ->
  d * 0.03281

drag = d3.behavior.drag()
  .on "drag", throttle ->
    item = items.child d3.select(this).datum()
    item.update
      x: Math.round scale.invert d3.event.x
      y: Math.round scale.invert d3.event.y

line = React.createClass
  componentDidMount: ->
    return if @props.item.fixed
    d3.select @refs.path.getDOMNode()
      .datum @props.id
      .call drag
  handleMouseOver: ->
    @props.onMouseOver()
  handleMouseOut: ->
    @props.onMouseOut()
  render: ->
    me = @props.item
    scaled = me.points.map((p) -> p.map((d) -> scale d))
    g
      ref: "path"
      className: "item"
      transform: "translate(#{scale me.x},#{scale me.y})rotate(#{me.a})"
      onMouseOver: @handleMouseOver
      onMouseOut: @handleMouseOut
      circle
        cx: scaled[0][0]
        cy: scaled[0][1]
        r: 5
        fill: if @props.item.fixed then "none" else "grey"
      path
        d: "M#{scaled.map((p) -> p.join ',').join 'L'}Z"
        stroke: me.color
        "data-id": @props.id

grid = React.createClass
  render: ->
    g
      className: grid
      for tick in scale.ticks()
        path
          d: "M#{scale tick},0V#{focus.height}"
          stroke: "#CCC"
      for tick in scale.ticks()
        path
          d: "M0,#{scale tick}H#{focus.width}"
          stroke: "#CCC"

tip = React.createClass
  render: ->
    x = if @props.tip isnt "" then scale @props.mouseX else -999
    y = if @props.tip isnt "" then scale @props.mouseY else -999
    text
      className: "tooltip"
      transform: "translate(#{x-6},#{y-6})"
      @props.tip

app = React.createClass
  getInitialState: ->
    mouseX: 0
    mouseY: 0
    tip: ""
  componentDidMount: ->
    d3.select @refs.main.getDOMNode()
      .on "mousemove", =>
        mouseX = scale.invert d3.event.clientX - margin.left
        mouseY = scale.invert d3.event.clientY - margin.top
        @setState {mouseX, mouseY}
  render: ->
    cmx = Math.round @state.mouseX
    cmy = Math.round @state.mouseY
    ftx = Math.round(10 * scaleFt @state.mouseX)/10
    fty = Math.round(10 * scaleFt @state.mouseY)/10
    div null,
      svg
        width: chart.width
        height: chart.height
        g
          transform: "translate(#{margin.left},#{margin.top})"
          ref: "main"
          rect
            width: chart.width
            height: chart.height
            fill: "white"
          grid()
          [0...@props.items.length].map (id) =>
            item = @props.items[id]
            onMouseOver = =>
              @setState tip: item.name
            onMouseOut = =>
              @setState tip: ""
            line {id, item, onMouseOver, onMouseOut}
          tip @state
      div
        className: "status"
        ref: "status"
        "#{cmx}cm, #{cmy}cm - #{ftx}ft, #{fty}ft"

fb.on "value", (d) ->
  React.renderComponent app(d.val()),
    document.getElementById "app"
