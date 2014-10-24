_   = require \underscore
C   = require \../../../../collection
V   = require \../../../../view
Map = require \../../../../view .map
Egl = require \../../edge-glyph
N   = require \./node

var edges-attend, edges-steer, nodes-steer, ga, g-attend, gs, g-steer

Map.on \cooled, ->
  ~function render g, edges, fn-get-hub, fn-is-hub, css-class
    return unless hub = _.find @d3f.nodes!, fn-get-hub
    g-child = g.append \svg:g
    for edge in edges
      [src, tar] = [edge.source, edge.target]
      g-child.append \svg:line
        .attr \x1, if fn-is-hub src then hub.x else src.x
        .attr \y1, if fn-is-hub src then hub.y else src.y
        .attr \x2, if fn-is-hub tar then hub.x else tar.x
        .attr \y2, if fn-is-hub tar then hub.y else tar.y
        .attr \class, "edge #{css-class}"
    g-child

  # attends
  if edges-attend
    edges = _.reject edges-attend, (edge) ->
      !!_.find nodes-steer, -> it._id in [edge.source._id, edge.target._id]
    g-attend := render ga, edges, N.is-annual-conference, N.is-conference-yyyy, \bil-attend

  # steering
  return unless edges = edges-steer
  return unless g-steer := render gs, edges, N.is-steering, N.is-steering, \bil-steer
  glyphs = g-steer.selectAll \g.edge-glyphs
    .data edges
    .enter!append \svg:g
      .attr \class, \edge-glyphs
  glyphs.each Egl.append
  glyphs.attr \transform Egl.get-transform

Map.on \pre-cool ->
  g-attend?remove!
  g-steer?remove!

Map.on \pre-render (ents) ->
  function is-conference-yyyy then N.is-conference-yyyy it.source or N.is-conference-yyyy it.target
  function is-steering then it.how is \member and (N.is-steering it.source or N.is-steering it.target)

  edges-attend := _.filter ents.edges, is-conference-yyyy
  edges-steer  := _.filter ents.edges, is-steering
  nodes-steer  := _.map edges-steer, -> if N.is-steering it.source then it.target else it.source
  ents.edges = _.difference ents.edges, edges-attend, edges-steer

  # inject info required by node renderer
  N.edges-attend = edges-attend
  N.nodes-steer = nodes-steer

Map.on \render ->
  ~function add-overlay name
    g = @svg.append \svg:g .attr \class, name
    V.map-toolbar.on "toggle-#name", -> g.attr \display, if it then '' else \none
    g
  ga := add-overlay \bil-attend
  gs := add-overlay \bil-steer
