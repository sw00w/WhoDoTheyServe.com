F = require \fs
_ = require \underscore
C = require \../../collection
H = require \../../helper
M = require \../../model

const ICON-SIZE = 20

H.insert-css F.readFileSync __dirname + \/node.css

module.exports = me =
  data: ->
    _.map C.Nodes.models, (m) -> m.toJSON-T!

  init: (svg, d3-force) ~>
    @nodes = svg.selectAll \g.node
      .data d3-force.nodes!
      .enter!append \svg:g
        .attr \class, -> "node id_#{it._id} #{if me.is-you it then \you}"

    @nodes.append \svg:circle
      .attr \r, -> 5 + it.weight + if me.is-you it then 10 else 0

    @nodes.append \svg:a
      .attr \xlink:href, -> "#/node/#{it._id}"
      .append \svg:text
        .attr \dy, 4
        .attr \text-anchor, \middle
        .text -> it.name

    if glyphs = (JSON.parse M.Hive.Graph.get \value).glyphs then
      for glyph in glyphs
        g = svg.select "g.id_#{glyph.id}"
        if glyph.ucid
          g.append \text
            .attr \class, \fa
            .attr \font-family, \FontAwesome
            .attr \font-size, ICON-SIZE
            .attr \x, - ICON-SIZE * 0.5
            .attr \y, - ICON-SIZE * 0.75
            .text -> glyph.ucid
        else if glyph.img
          size = glyph.size / \x
          g.append \svg:image
            .attr \xlink:href, glyph.img
            .attr \x     , x = -size.0 / 2
            .attr \y     , y = -size.1 - 12
            .attr \width , size.0
            .attr \height, size.1
          if size.2 then
            g.append \svg:rect
              .attr \x     , x - 1
              .attr \y     , y - 1
              .attr \width , 2 + parseInt size.0
              .attr \height, 2 + parseInt size.1

  is-bis: ->
    /^BIS /.test it.name

  is-you: ->
    /^YOU/.test it.name

  on-tick: ~>
    @nodes.attr \transform, ~> "translate(#{it.x},#{it.y})"
