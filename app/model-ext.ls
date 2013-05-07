_ = require \underscore
C = require \./collection
H = require \./helper
M = require \./model

exports.init = ->
  M.Edge .= extend do
    toJSON-T: (opts) ->
      j = @toJSON opts
      _.extend j, a_node_name:(C.Nodes.get @get \a_node_id)?get \name
      _.extend j, b_node_name:(C.Nodes.get @get \b_node_id)?get \name
      _.extend j, a_is_eq: \eq is @get \a_is
      _.extend j, a_is_lt: \lt is @get \a_is
      j
    in_range: (y_from, y_to) ->
      yf = @get(\year_from) or 0
      yt = @get(\year_to)   or 9999
      not (yf > y_to or yt < y_from)

  add-factory-method M.Evidence
  add-factory-method M.Edge
  add-factory-method M.Node
  add-factory-method M.Note
  add-factory-method M.Session
  add-factory-method M.Signup
  add-factory-method M.Sys
  add-factory-method M.User

  function add-factory-method Model then
    Model.create = ->
      (m = new Model!).id = it
      return m
