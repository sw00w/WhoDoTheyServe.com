Assert  = require \assert
Brsify  = require \browserify
Brfs    = require \brfs
Cachify = require \cacheify # really speeds up bundling app.js!
Cron    = require \cron
Emitter = require \events .EventEmitter
Expsify = require \exposify
Fs      = require \fs
Gaze    = require \gaze
Globule = require \globule
_       = require \lodash
Lup     = require \levelup
Md      = require \marked
Memdown = require \memdown
Path    = require \path
Shell   = require \shelljs/global
WFib    = require \wait.for .launchFiber
W4      = require \wait.for .for
W4m     = require \wait.for .forMethod
Dir     = require \./constants .dir
Dirname = require \./constants .dirname
G       = require \./growl

const NMODULES = './node_modules'

pruner = new Cron.CronJob cronTime:'*/10 * * * *', onTick:prune-empty-dirs
tasks  =
  jade:
    cmd : "node #NMODULES/jade/bin/jade.js --out $OUT $IN"
    ixt : \jade
    oxt : \html
    mixn: \_
  livescript:
    cmd : "#NMODULES/LiveScript/bin/lsc --output $OUT $IN"
    ixt : \ls
    oxt : \js
    xsub: 'json.js->json'
  markdown:
    cmd : markdown
    ixt : \md
    oxt : \html
  static:
    cmd : 'cp $IN $OUT'
    ixt : '+(css|eot|gif|html|jpg|js|json|otf|pem|png|svg|ttf|txt|woff)'
  stylus:
    cmd : "#NMODULES/stylus/bin/stylus -u nib --out $OUT $IN"
    ixt : \styl
    oxt : \css
    mixn: \_

module.exports = me = (new Emitter!) with
  bundle: ->
    bundle-lib!
    bundle-app!

  compile-files: ->
    try
      for tid of tasks then compile-batch tid
      finalise!
    catch e then G.err e

  delete-files: ->
    log "delete-files #{pwd!}"
    Assert.equal pwd!, Dir.build.DEV
    W4 exec, "bash -O extglob -O dotglob -c 'rm -rf !(node_modules|task)'"

  delete-modules: ->
    log "delete-modules #{pwd!}"
    Assert.equal pwd!, Dir.build.DEV
    rm '-rf' "./node_modules"

  refresh-modules: ->
    Assert.equal pwd!, Dir.build.DEV
    W4 exec, 'npm -v'
    W4 exec, 'npm prune'
    W4 exec, 'npm install'

  start: ->
    G.say 'build started'
    try
      pushd Dir.ROOT
      for tid of tasks then start-watching tid
    finally
      popd!
    pruner.start!

  stop: ->
    pruner.stop!
    for , t of tasks then t.gaze?close!
    G.say 'build stopped'

## helpers

const LIBS =
  # bundle order is random: https://github.com/substack/node-browserify/issues/355
  # UPDATE: this now appears to be fixed in browserify, so files get bundled in the correct order.
  \./lib-3p/underscore.mixin.deepExtend
  \./lib-3p/Autolinker
  \./lib-3p/backbone-deep-model
  \./lib-3p/backbone.routefilter
  \./lib-3p/backbone-validation
  \./lib-3p/backbone-validation-bootstrap
  \./lib-3p/bootstrap/js/bootstrap-dropdown
  \./lib-3p/bootstrap/js/bootstrap-typeahead
  \./lib-3p/bootstrap-combobox
  \./lib-3p/transparency
  \./lib-3p/jquery.multiple.select
  \./lib-3p/jquery.timeago
  \./lib-3p-ext/jquery

function bundle path, fn-setup
  pushd "#{Dir.build.dev.SITE}/app"
  try
    W4 (cb) ->
      t0 = process.hrtime!
      b = fn-setup!
      out = Fs.createWriteStream path
        ..on \finish, ->
          t = process.hrtime t0
          G.say "Bundled #path (#{Math.floor out.bytesWritten/1024}k) in #{t.0}.#{t.1}s"
          cb!
        ..on \error, ->
          G.alert "Bundle error #it"
          cb it
      b.bundle detectGlobals:false, insertGlobals:false .pipe out
  finally
    popd!

cache = brfs:(Lup Memdown), exposify:Lup Memdown
Expsify.config = backbone:\window.Backbone underscore:\window._
function bundle-app opath
  bundle \app.js, ->
    # Cacheify has no concept of dependencies so we must ensure an update to a brfs'd
    # file invalidates its parent js. Quick and dirty method is to clear the whole cache!
    if /\.(html|css)$/.test opath # file types which can be brfs'd
      log "cache invalidated by #opath"
      cache.brfs = Lup Memdown
      cache.exposify = Lup Memdown
    b = Brsify \./boot.js
      ..require \./lib-3p/Autolinker  , expose:\Autolinker
      ..require \./lib-3p/transparency, expose:\transparency
      ..transform Cachify Expsify, cache.exposify
      ..transform Cachify Brfs, cache.brfs
    for l in LIBS then b.external l
    b

function bundle-lib
  bundle \lib.js, ->
    b = Brsify LIBS
    for l in LIBS then b.require l
    b

function compile t, ipath, cb
  odir = Path.dirname opath = get-opath t, ipath
  mkdir '-p', odir # stylus fails if outdir doesn't exist
  switch typeof t.cmd
  | \string =>
    cmd = t.cmd.replace(\$IN, "'#ipath'").replace \$OUT, "'#odir'"
    code, res <- exec cmd
    log code, res if code
    cb (if code then res else void), opath
  | \function =>
    e <- t.cmd ipath, opath
    cb e, opath

function compile-batch tid
  t = tasks[tid]
  w = W4m t.gaze, \watched
  files = [ f for dir, paths of w for f in paths
    when '/' isnt f.slice -1 and (Path.basename f).0 isnt t.mixn ]
  files = _.filter files, t.isMatch # TODO: remove when gaze fixes issue 104
  info = "#{files.length} #tid files"
  G.say "compiling #info..."
  for f in files then W4 compile, t, f
  G.ok "...done #info!"

function copy-package-json
  # ensure package.json resides alongside /api and /app
  cp \-f, './package.json', './site'

function get-opath t, ipath
  p = ipath.replace("#{Dir.ROOT}/", '').replace t.ixt, t.oxt
  return p unless (xsub = t.xsub?split '->')?
  p.replace xsub.0, xsub.1

function markdown ipath, opath, cb
  e, html <- Md cat ipath
  html.to opath unless e?
  cb e

function finalise ipath, opath
  const API = <[ /api/ /api.ls ]>
  const APP = <[ /app/ /app.ls ]>
  function contains then _.any it, -> _.contains ipath, it
  function contains-base then contains ["#{Dir.ROOT}/#it/"]
  if ipath # partial build
    log ipath
    return if contains-base \task
    me.emit \built-api unless contains APP
    ipath-rel = ipath.replace "#{Dir.SITE}/app", '.'
    if (_.any LIBS, -> _.contains ipath-rel, it) then bundle-lib! else
      bundle-app opath unless contains-base \test or contains API
    me.emit \built-app unless contains API
  else # full build
    me.emit \built-api
    bundle-lib!
    bundle-app!
    me.emit \built-app
  copy-package-json!
  me.emit \built

function prune-empty-dirs
  unless pwd! is Dir.build.DEV then return log 'bypass prune-empty-dirs'
  code, out <- exec "find . -type d -empty -delete"
  G.err "prune failed: #code #out" if code

function start-watching tid
  log "start watching #tid"
  Assert.equal pwd!, Dir.ROOT
  ixt = (t = tasks[tid]).ixt
  dirs = "#{Dirname.SITE},#{Dirname.TASK},#{Dirname.TEST}"
  # TODO: remove t.isMatch when gaze fixes https://github.com/shama/gaze/issues/104
  t.isMatch = (ipath) -> Globule.isMatch t.patterns, (ipath.replace "#{Dir.ROOT}/", '')
  t.gaze = Gaze t.patterns = [ "*.#ixt" "{#dirs}/**/*.#ixt" ], ->
    act, ipath <- t.gaze.on \all
    return if '/' is ipath.slice -1 # BUG: Gaze might fire when dir added
    return unless t.isMatch ipath # TODO: remove when gaze fixes issue 104
    log act, ipath
    WFib ->
      if t.mixn? and (Path.basename ipath).0 is t.mixn then
        try
          compile-batch tid
          finalise ipath
        catch e then G.err e
      else switch act
        | \added, \changed, \renamed
          try opath = W4 compile, t, ipath
          catch e then return G.err e
          G.ok opath
          finalise ipath, opath
        | \deleted
          try W4m Fs, \unlink, opath = get-opath t, ipath
          catch e then throw e unless e.code is \ENOENT # not found i.e. already deleted
          G.ok "Delete #opath"
          finalise ipath, opath
