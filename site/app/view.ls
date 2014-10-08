F           = require \fs # browserified
H           = require \./helper
V           = require \./view-engine
V-Footer    = require \./view/footer
V-Latest    = require \./view/latest
V-Map       = require \./view/map
V-MapTBar   = require \./view/map/toolbar
V-NavBar    = require \./view/navbar
V-Sys       = require \./view/sys

H.insert-css-seo F.readFileSync __dirname + \/view.css

# cannot refactor since Brfs requires this exact code format
D-About         = F.readFileSync __dirname + \/doc/about.html
T-EdgeEdit      = F.readFileSync __dirname + \/view/edge/edit.html
T-Edge          = F.readFileSync __dirname + \/view/edge.html
T-Edges         = F.readFileSync __dirname + \/view/edges.html
T-EdgesHead     = F.readFileSync __dirname + \/view/edges-head.html
T-EvidenceEdit  = F.readFileSync __dirname + \/view/evidence-edit.html
T-Evidences     = F.readFileSync __dirname + \/view/evidences.html
T-EvidencesHead = F.readFileSync __dirname + \/view/evidences-head.html
T-MapEdit       = F.readFileSync __dirname + \/view/map/edit.html
T-MapInfo       = F.readFileSync __dirname + \/view/map/info.html
T-Maps          = F.readFileSync __dirname + \/view/maps.html
T-Meta          = F.readFileSync __dirname + \/view/meta.html
T-Node          = F.readFileSync __dirname + \/view/node.html
T-NodeEdit      = F.readFileSync __dirname + \/view/node/edit.html
T-NodeEdgesA    = F.readFileSync __dirname + \/view/node/edges-a.html
T-NodeEdgesB    = F.readFileSync __dirname + \/view/node/edges-b.html
T-NoteEdit      = F.readFileSync __dirname + \/view/note-edit.html
T-Nodes         = F.readFileSync __dirname + \/view/nodes.html
T-NodesHead     = F.readFileSync __dirname + \/view/nodes-head.html
T-Notes         = F.readFileSync __dirname + \/view/notes.html
T-NotesHead     = F.readFileSync __dirname + \/view/notes-head.html
T-User          = F.readFileSync __dirname + \/view/user.html
T-UserEdit      = F.readFileSync __dirname + \/view/user/edit.html
T-UserSignin    = F.readFileSync __dirname + \/view/user/signin.html
T-UserSigninErr = F.readFileSync __dirname + \/view/user/signin-error.html
T-Users         = F.readFileSync __dirname + \/view/users.html
T-Version       = F.readFileSync __dirname + \/view/version.html

me = exports # not clear why refactoring to 'module.exports' breaks things
  ## views
  ..doc-about       = new V.DocuView document:D-About        , el:\.view>.main
  ..edge            = new V.InfoView template:T-Edge         , el:\.view>.main
  ..edge-a-node-sel = new V.SelectView                         sel:\#a_node_id
  ..edge-b-node-sel = new V.SelectView                         sel:\#b_node_id
  ..edge-edit       = new V.EditView template:T-EdgeEdit     , el:\.view>.main
  ..edges           = new V.ListView template:T-Edges        , el:\.view>.edges, opts:{ fetch:false }
  ..edges-head      = new V.InfoView template:T-EdgesHead    , el:\.view>.main
  ..evidence-edit   = new V.EditView template:T-EvidenceEdit , el:\.view>.evidence-edit
  ..evidences       = new V.ListView template:T-Evidences    , el:\.view>.evidences
  ..evidences-head  = new V.InfoView template:T-EvidencesHead, el:\.view>.evidences-head
  ..footer          = new V-Footer                             el:\.footer
  ..latest          = new V-Latest                             el:\.view>.main
  ..map             = new V-Map                                el:\.view>.map
  ..map-edit        = new V.EditView template:T-MapEdit      , el:\.view>.map-edit
  ..map-info        = new V.InfoView template:T-MapInfo      , el:\.view>.map-info
  ..map-meta        = new V.InfoView template:T-Meta         , el:\.view>.map-meta
  ..map-nodes-sel   = new V.MultiSelectView                    sel:'form.map #nodes', opts:{ filter:true maxHeight:800 width:370 }
  ..map-toolbar     = new V-MapTBar                            el:\.view>.map-toolbar
  ..maps            = new V.ListView template:T-Maps         , el:\.view>.maps, opts:{ fetch:false }
  ..meta            = new V.InfoView template:T-Meta         , el:\.view>.meta
  ..navbar          = new V-NavBar                             el:\.navigator
  ..node            = new V.InfoView template:T-Node         , el:\.view>.main
  ..node-edit       = new V.EditView template:T-NodeEdit     , el:\.view>.main
  ..node-edges-a    = new V.ListView template:T-NodeEdgesA   , el:\.view>.node-edges-a
  ..node-edges-b    = new V.ListView template:T-NodeEdgesB   , el:\.view>.node-edges-b
  ..node-edges-head = new V.InfoView template:T-EdgesHead    , el:\.view>.node-edges-head
  ..nodes           = new V.ListView template:T-Nodes        , el:\.view>.nodes, opts:{ fetch:false }
  ..nodes-head      = new V.InfoView template:T-NodesHead    , el:\.view>.main
  ..note-edit       = new V.EditView template:T-NoteEdit     , el:\.view>.note-edit
  ..notes           = new V.ListView template:T-Notes        , el:\.view>.notes
  ..notes-head      = new V.InfoView template:T-NotesHead    , el:\.view>.notes-head
  ..sys             = new V-Sys                                el:\.view>.main
  ..user            = new V.InfoView template:T-User         , el:\.view>.main
  ..user-edit       = new V.EditView template:T-UserEdit     , el:\.view>.main
  ..user-signin     = new V.EditView template:T-UserSignin   , el:\.view>.main
  ..user-signin-err = new V.InfoView template:T-UserSigninErr, el:\.view>.main, opts:{ query-string:true }
  ..user-signout    = new V.InfoView template:''             , el:\.view>.main
  ..user-signup     = new V.EditView template:T-UserEdit     , el:\.view>.main
  ..users           = new V.ListView template:T-Users        , el:\.view>.users
  ..version         = new V.InfoView template:T-Version      , el:\.view-version

  ## helper functions

  ..finalise = ->
    # use a delgated event since view may still be rendering asyncly
    $ \.view .on \focus, 'input[type=text]', ->
      # defer, to workaround Chrome mouseup bug
      # http://stackoverflow.com/questions/2939122/problem-with-chrome-form-handling-input-onfocus-this-select
      _.defer ~> @select!
    <- _.defer
    $ \.btn-new:visible:first .focus!
    $ \.view .addClass \ready
    $ \.timeago .timeago!

  ..reset = ->
    $ '.view' .off \focus, 'input[type=text]' .removeClass \ready

    # handle view persistance -- some views (e.g. map) should not be cleared down, for performance
    $ '.view>:not(.persist-once)' .hide!
    $ '.view>:not(.persist-once,.persist)' .off! # so different views can use same element
    $ '.view>:not(.persist-once,.persist)' .empty! # leave persistent views e.g. map
    $ '.view>.persist-once' .removeClass \persist-once

    # handle errors
    $ '.alert-error' .removeClass \active    # clear any error alert location overrides
    $ '.view>.alert-error' .addClass \active # reset back to default

    me.navbar.render!
    V.ResetEditView!
