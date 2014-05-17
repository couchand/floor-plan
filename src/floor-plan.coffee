# floor plan

fb = new Firebase "https://blazing-fire-9139.firebaseio.com/"
items = fb.child("items")

#window.send = (d) ->
#  console.log "sending: ", d
#  fb.set d, (e) ->
#    if e
#      console.error "error: ", e
#    else
#      console.log "sent"
#  d

{div, svg, g, path, circle, rect} = React.DOM

chart =
  width: 960
  height: 600

margin =
  left: 10
  top: 10

scale = d3.scale.linear()
  .range [0, Math.min chart.width, chart.height]
  .domain [0, 1000]

scaleFt = (d) ->
  d * 0.03281

drag = d3.behavior.drag()
  .on "drag", ->
    item = items.child d3.select(this).datum()
    item.update
      x: Math.round scale.invert d3.event.x
      y: Math.round scale.invert d3.event.y

line = React.createClass
  componentDidMount: ->
    d3.select @refs.path.getDOMNode()
      .datum @props.id
      .call drag
  render: ->
    me = @props.item
    scaled = me.points.map((p) -> p.map((d) -> scale d))
    g
      ref: "path"
      transform: "translate(#{scale me.x},#{scale me.y})rotate(#{me.a})"
      circle
        cx: scaled[0][0]
        cy: scaled[0][1]
        r: 5
        fill: "grey"
      path
        d: "M#{scaled.map((p) -> p.join ',').join 'L'}Z"
        stroke: me.color
        strokeWidth: 3
        fill: "none"
        "data-id": @props.id

grid = React.createClass
  render: ->
    g
      className: grid
      for tick in scale.ticks()
        path
          d: "M#{scale tick},0V#{chart.height}"
          stroke: "#CCC"
      for tick in scale.ticks()
        path
          d: "M0,#{scale tick}H#{chart.width}"
          stroke: "#CCC"

app = React.createClass
  componentDidMount: ->
    d3.select @refs.main.getDOMNode()
      .on "mousemove", =>
        x = scale.invert d3.event.clientX - margin.left
        y = scale.invert d3.event.clientY - margin.top
        cmx = Math.round x
        cmy = Math.round y
        ftx = Math.round(10 * scaleFt x)/10
        fty = Math.round(10 * scaleFt y)/10
        d3.select @refs.status.getDOMNode()
          .text "#{cmx}cm, #{cmy}cm - #{ftx}ft, #{fty}ft"
  render: ->
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
          (line {id, item} for id, item of @props.items)
      div
        className: "status"
        ref: "status"

fb.on "value", (d) ->
  React.renderComponent app(d.val()),
    document.getElementById "app"
