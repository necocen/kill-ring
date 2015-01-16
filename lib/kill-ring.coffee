{Point, Range, CompositeDisposable} = require 'atom'

module.exports = KillRing =
  subscriptions: null
  buffer: null
  lastYankRange: null

  activate: (state) ->

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # setup ring buffer
    RingBuffer = require "./ring-buffer"
    @buffer = new RingBuffer([], 4)

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-text-editor', 'kill-ring:set-mark': (event) => @setMark(event)
    @subscriptions.add atom.commands.add 'atom-text-editor', 'kill-ring:kill-selection': (event) => @killSelection(event)
    @subscriptions.add atom.commands.add 'atom-text-editor', 'kill-ring:kill-line': (event) => @killLine(event)
    @subscriptions.add atom.commands.add 'atom-text-editor', 'kill-ring:yank': (event) => @yank(event)
    @subscriptions.add atom.commands.add 'atom-text-editor', 'kill-ring:yank-pop': (event) => @yankPop(event)

  deactivate: ->
    @subscriptions.dispose()

  setMark: (event) ->
    console.log 'KR: set-mark'

  killSelection: (event) ->
    editor = event.target.model
    return unless editor?
    selection = editor.getLastSelection()
    return unless selection?
    range = selection.getBufferRange()
    text = editor.getTextInRange(range)
    return if text.length is 0
    @buffer.push(text)
    editor.buffer.delete(range)

  killLine: (event) ->
    editor = event.target.model
    return unless editor?
    cursor = editor.getLastCursor()
    return unless cursor?
    editor.transact =>
      range = new Range(cursor.getBufferPosition(), new Point(cursor.getBufferRow(), Infinity))
      text = editor.getTextInRange(range)
      if text.length is 0 # remove \n if the cursor is on end-of-line
        range = new Range(cursor.getBufferPosition(), new Point(cursor.getBufferRow() + 1, 0))
        text = editor.getTextInRange(range)
      return if text.length is 0
      @buffer.push(text)
      editor.buffer.delete(range)

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
