F = require \fs
C = require \../../collection
H = require \../../helper
R = require \../../router
V = require \../../view

H.insert-css F.readFileSync __dirname + \/edit.css

module.exports.init = ->
  V.map-edit
    ..on \destroyed, ->
      V.navbar.render!
      navigate \session

    ..on \rendered, ->
      V.map-nodes-sel
        ..render C.Nodes, \name, _.pluck (it.get \nodes), \_id
        ..on \click, ->
          if it.checked then V.graph.add-node it.value else V.graph.remove-node it.value
          V.graph.render is-long-settle:true

    ..on \saved, (map, is-new) ->
      V.navbar.render!
      navigate "map/#{map.id}" if is-new

    ..on \serialized, ->
      # save all selected nodes -- some may have been filtered out of the d3 visualisation in
      # which case they won't have (x, y)
      sel-nodes = V.map-nodes-sel.get-selected-ids!
      d3-nodes  = V.graph.get-nodes!
      it.attributes.nodes = _.map sel-nodes, (id) ->
        d3-node = _.find d3-nodes, -> it.id is id
        node = _id:id
        node <<< { x:d3-node.x, y:d3-node.y } if d3-node?
        node

# helpers

function navigate then R.navigate it, trigger:true
