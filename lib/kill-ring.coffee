{CompositeDisposable} = require 'atom'

module.exports = KillRing =
  subscriptions: null

  activate: (state) ->

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-text-editor', 'kill-ring:set-mark': => @setMark()

  deactivate: ->
    @subscriptions.dispose()

  setMark: ->
    console.log 'KR: set-mark'
