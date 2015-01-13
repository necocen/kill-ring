KillRingView = require './kill-ring-view'
{CompositeDisposable} = require 'atom'

module.exports = KillRing =
  killRingView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    @killRingView = new KillRingView(state.killRingViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @killRingView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'kill-ring:toggle': => @toggle()

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @killRingView.destroy()

  serialize: ->
    killRingViewState: @killRingView.serialize()

  toggle: ->
    console.log 'KillRing was toggled!'

    if @modalPanel.isVisible()
      @modalPanel.hide()
    else
      @modalPanel.show()
