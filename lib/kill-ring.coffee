{Point, Range, CompositeDisposable} = require 'atom'

module.exports = KillRing =
  subscriptions: null
  buffer: null
  lastYankRange: null
  markers: {}

  activate: (state) ->

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # setup ring buffer
    RingBuffer = require "./ring-buffer"
    @buffer = new RingBuffer([], 4)

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-text-editor', 'kill-ring:set-mark': (event) => @setMark(event)
    @subscriptions.add atom.commands.add 'atom-text-editor', 'kill-ring:kill-region': (event) => @killRegion(event)
    @subscriptions.add atom.commands.add 'atom-text-editor', 'kill-ring:kill-selection': (event) => @killSelection(event)
    @subscriptions.add atom.commands.add 'atom-text-editor', 'kill-ring:kill-line': (event) => @killLine(event)
    @subscriptions.add atom.commands.add 'atom-text-editor', 'kill-ring:yank': (event) => @yank(event)
    @subscriptions.add atom.commands.add 'atom-text-editor', 'kill-ring:yank-pop': (event) => @yankPop(event)

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
    cursor = editor.getLastCursor()
    return unless cursor?
    marker = @markers[editor.id]
    return unless marker?
    return unless marker.isValid()

    cursorPosition = cursor.getBufferPosition()
    markerPosition = marker.getHeadBufferPosition()
    return if cursorPosition.isEqual(markerPosition)
    range = null
    if cursorPosition.isLessThan(markerPosition)
      range = new Range(cursorPosition, markerPosition)
    else
      range = new Range(markerPosition, cursorPosition)
    @_killRange editor, range, false

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
    @lastYankRange = editor.setTextInBufferRange(new Range(cursor.getBufferPosition(), cursor.getBufferPosition()), @buffer.peek())
    subscription = editor.onDidChangeCursorPosition (event) =>
      @lastYankRange = null
      subscription.dispose()

  yankPop: (event) ->
    return if @lastYankRange is null # last command is not yank
    editor = event.target.model
    return unless editor?
    @lastYankRange = editor.setTextInBufferRange(@lastYankRange, @buffer.peekback())
    subscription = editor.onDidChangeCursorPosition (event) =>
      @lastYankRange = null
      subscription.dispose()

  _killRange: (editor, range, copy) ->
    editor.transact =>
      text = editor.getTextInRange(range)
      return if text.length is 0
      @buffer.push(text)
      editor.buffer.delete(range) if copy is false
