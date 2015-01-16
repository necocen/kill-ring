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
    @subscriptions.add atom.commands.add 'atom-text-editor', 'kill-ring:set-mark': => @setMark()
    @subscriptions.add atom.commands.add 'atom-text-editor', 'kill-ring:kill-selection': => @killSelection()
    @subscriptions.add atom.commands.add 'atom-text-editor', 'kill-ring:kill-line': => @killLine()
    @subscriptions.add atom.commands.add 'atom-text-editor', 'kill-ring:yank': => @yank()
    @subscriptions.add atom.commands.add 'atom-text-editor', 'kill-ring:yank-pop': => @yankPop()

  deactivate: ->
    @subscriptions.dispose()

  setMark: ->
    console.log 'KR: set-mark'

  killSelection: ->
    editor = atom.workspace.getActiveTextEditor()
    return if editor is null
    selection = editor.getLastSelection()
    return if selection is null
    range = selection.getBufferRange()
    text = editor.getTextInRange(range)
    return if text.length is 0
    @buffer.push(text)
    editor.buffer.delete(range)

  killLine: ->
    editor = atom.workspace.getActiveTextEditor()
    return if editor is null
    cursor = editor.getLastCursor()
    return if cursor is null
    editor.transact =>
      range = new Range(cursor.getBufferPosition(), new Point(cursor.getBufferRow(), Infinity))
      text = editor.getTextInRange(range)
      if text.length is 0 # remove \n if the cursor is on end-of-line
        range = new Range(cursor.getBufferPosition(), new Point(cursor.getBufferRow() + 1, 0))
        text = editor.getTextInRange(range)
      return if text.length is 0
      @buffer.push(text)
      editor.buffer.delete(range)

  yank: ->
    editor = atom.workspace.getActiveTextEditor()
    return if editor is null
    cursor = editor.getLastCursor()
    return if cursor is null
    @lastYankRange = editor.setTextInBufferRange(new Range(cursor.getBufferPosition(), cursor.getBufferPosition()), @buffer.peek())
    subscription = editor.onDidChangeCursorPosition (event) =>
      @lastYankRange = null
      subscription.dispose()

  yankPop: ->
    return if @lastYankRange is null # last command is not yank
    editor = atom.workspace.getActiveTextEditor()
    return if editor is null
    @lastYankRange = editor.setTextInBufferRange(@lastYankRange, @buffer.peekback())
    subscription = editor.onDidChangeCursorPosition (event) =>
      @lastYankRange = null
      subscription.dispose()
