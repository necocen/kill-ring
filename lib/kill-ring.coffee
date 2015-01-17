{Point, Range, CompositeDisposable} = require 'atom'

module.exports = KillRing =
  config:
    killRingSize:
      title: "Kill Ring Size"
      description: 'Number of strings kill-ring can save. If set less than current value, current kill-ring is truncated.'
      type: 'integer'
      default: 64
      minimum: 1

  subscriptions: null
  buffer: null
  lastYankRange: null
  markers: {}

  activate: (state) ->

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # setup ring buffer
    RingBuffer = require "./ring-buffer"
    @buffer = new RingBuffer([], atom.config.get 'kill-ring.killRingSize')

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-text-editor', 'kill-ring:set-mark': (event) => @setMark(event)
    @subscriptions.add atom.commands.add 'atom-text-editor', 'kill-ring:kill-region': (event) => @killRegion(event)
    @subscriptions.add atom.commands.add 'atom-text-editor', 'kill-ring:copy-region-as-kill': (event) => @copyRegionAsKill(event)
    @subscriptions.add atom.commands.add 'atom-text-editor', 'kill-ring:kill-selection': (event) => @killSelection(event)
    @subscriptions.add atom.commands.add 'atom-text-editor', 'kill-ring:kill-line': (event) => @killLine(event)
    @subscriptions.add atom.commands.add 'atom-text-editor', 'kill-ring:yank': (event) => @yank(event)
    @subscriptions.add atom.commands.add 'atom-text-editor', 'kill-ring:yank-pop': (event) => @yankPop(event)
    @subscriptions.add atom.commands.add 'atom-text-editor', 'kill-ring:exchange-point-and-mark': (event) => @exchangePointAndMark(event)
    @subscriptions.add atom.config.observe 'kill-ring.killRingSize', (newValue) => @buffer.setSize(newValue)

  deactivate: ->
    @subscriptions.dispose()
    marker.destroy() for id, marker in @markers

  setMark: (event) ->
    editor = event.target.model
    return unless editor?
    cursor = editor.getLastCursor()
    return unless cursor?

    marker = @markers[editor.id]
    unless marker?
      marker = editor.markBufferPosition cursor.getBufferPosition(), {persistent: false}
      editor.decorateMarker marker, {type: 'gutter', class: 'kill-ring-marked', onlyHead: true}
      @markers[editor.id] = marker
    else
      marker.setHeadBufferPosition cursor.getBufferPosition()

  killRegion: (event) ->
    editor = event.target.model
    return unless editor?
    range = @_markedRange editor
    return unless range?
    @_killRange editor, range, false

  copyRegionAsKill: (event) ->
    editor = event.target.model
    return unless editor?
    range = @_markedRange editor
    return unless range?
    @_killRange editor, range, true

  killSelection: (event) ->
    editor = event.target.model
    return unless editor?
    selection = editor.getLastSelection()
    return unless selection?
    range = selection.getBufferRange()
    @_killRange editor, range, false

  killLine: (event) ->
    editor = event.target.model
    return unless editor?
    cursor = editor.getLastCursor()
    return unless cursor?
    range = new Range(cursor.getBufferPosition(), new Point(cursor.getBufferRow(), Infinity))
    text = editor.getTextInRange(range)
    if text.length is 0 # remove \n if the cursor is on end-of-line
      range = new Range(cursor.getBufferPosition(), new Point(cursor.getBufferRow() + 1, 0))
    @_killRange editor, range, false

  yank: (event) ->
    editor = event.target.model
    return unless editor?
    cursor = editor.getLastCursor()
    return unless cursor?
    text = @buffer.peek()
    return unless text?
    @lastYankRange = editor.setTextInBufferRange(new Range(cursor.getBufferPosition(), cursor.getBufferPosition()), text)
    subscription = editor.onDidChangeCursorPosition (event) =>
      @lastYankRange = null
      subscription.dispose()

  yankPop: (event) ->
    return if @lastYankRange is null # last command is not yank
    editor = event.target.model
    return unless editor?
    text = @buffer.peekback()
    return unless text?
    @lastYankRange = editor.setTextInBufferRange(@lastYankRange, text)
    subscription = editor.onDidChangeCursorPosition (event) =>
      @lastYankRange = null
      subscription.dispose()

  exchangePointAndMark: (event) ->
    editor = event.target.model
    return unless editor?
    cursor = editor.getLastCursor()
    return nil unless cursor?
    marker = @markers[editor.id]
    return nil unless marker?
    return nil unless marker.isValid()
    markerPosition = marker.getHeadBufferPosition()
    marker.setHeadBufferPosition cursor.getBufferPosition()
    cursor.setBufferPosition markerPosition, {autoscroll: true}

  _killRange: (editor, range, copy) ->
    editor.transact =>
      text = editor.getTextInRange(range)
      return if text.length is 0
      @buffer.push(text)
      editor.buffer.delete(range) if copy is false

  _markedRange: (editor) ->
    return nil unless editor?
    cursor = editor.getLastCursor()
    return nil unless cursor?
    marker = @markers[editor.id]
    return nil unless marker?
    return nil unless marker.isValid()
    return new Range(cursor.getBufferPosition(), marker.getHeadBufferPosition())
