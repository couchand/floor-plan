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

{svg, g, path, circle} = React.DOM

chart =
  width: 960
  height: 600

margin =
  left: 10
  top: 10

scale = d3.scale.linear()
  .range [0, Math.min chart.width, chart.height]
  .domain [0, 1000]

drag = d3.behavior.drag()
  .on "drag", ->
    item = items.child d3.select(this).datum()
    item.update
      x: d3.event.x
      y: d3.event.y

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
      transform: "translate(#{me.x},#{me.y})rotate(#{me.a})"
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

app = React.createClass
  render: ->
    svg
      width: chart.width
      height: chart.height
      g
        transform: "translate(#{margin.left},#{margin.top})"
        (line {id, item} for id, item of @props.items)

fb.on "value", (d) ->
  React.renderComponent app(d.val()),
    document.getElementById "app"
