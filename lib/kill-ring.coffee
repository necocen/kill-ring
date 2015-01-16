{Point, Range, CompositeDisposable} = require 'atom'

module.exports = KillRing =
  subscriptions: null
  killRing: null
  lastYankRange: null

  activate: (state) ->

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # setup kill-ring
    console.log 'KR: activate'
    @killRing = new KillRing([], 4)

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
    @killRing.push(text)
    editor.buffer.delete(range)

  killLine: ->
    editor = atom.workspace.getActiveTextEditor()
    return if editor is null
    cursor = editor.getCursors()[0]
    return if cursor is null
    editor.transact =>
      range = new Range(cursor.getBufferPosition(), new Point(cursor.getBufferRow(), Infinity))
      text = editor.getTextInRange(range)
      if text.length is 0 # remove \n if the cursor is on end-of-line
        range = new Range(cursor.getBufferPosition(), new Point(cursor.getBufferRow() + 1, 0))
        text = editor.getTextInRange(range)
      return if text.length is 0
      @killRing.push(text)
      editor.buffer.delete(range)

  yank: ->
    console.log @lastYankRange
    editor = atom.workspace.getActiveTextEditor()
    return if editor is null
    cursor = editor.getCursors()[0]
    return if cursor is null
    @lastYankRange = editor.setTextInBufferRange(new Range(cursor.getBufferPosition(), cursor.getBufferPosition()), @killRing.peek())
    subscription = editor.onDidChangeCursorPosition (event) =>
      @lastYankRange = null
      subscription.dispose()

  yankPop: ->
    return if @lastYankRange is null # last command is not yank
    editor = atom.workspace.getActiveTextEditor()
    return if editor is null
    @lastYankRange = editor.setTextInBufferRange(@lastYankRange, @killRing.peekback())
    subscription = editor.onDidChangeCursorPosition (event) =>
      @lastYankRange = null
      subscription.dispose()

class KillRing

  constructor: (buffer, size) ->
    _size = size
    _buffer = buffer
    _head = _buffer.length - 1
    _current = _head

    @push = (text) ->
      if _head >= _size
        _head = 0
      else
        _head += 1
      _buffer[_head] = text
      _current = _head

    @peek = ->
      if _current < 0
        ""
      else
        _buffer[_current]

    @peekback = ->
      if _current < 0
        ""
      else if _current is 0
        _current = _buffer.length - 1
        _buffer[_current]
      else
        _current -= 1
        _buffer[_current]

    normalize = ->
      if (_buffer.length is _size) and (_current > 0)
        newBuffer = _buffer[(_current + 1)..].concat(_buffer[0.._current])
        _buffer = newBuffer

    @getSize = -> _size
    @setSize = (newSize) ->
      normalize()
      if newSize < _buffer.length
        _buffer = _buffer[(_buffer.length - newSize)..]
