{CompositeDisposable} = require 'atom'

module.exports = KillRing =
  subscriptions: null
  killRing: null

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
    @subscriptions.add atom.commands.onWillDispatch (event) -> console.log(event.type)
    # cursor:movedを見て状況判断できそう

  deactivate: ->
    @subscriptions.dispose()

  setMark: ->
    console.log 'KR: set-mark'

  killSelection: ->
    console.log 'KR: kill-selection'

  killLine: ->
    editor = atom.workspace.getActiveTextEditor()
    return if editor is null
    editor.transact =>
      selection = editor.getSelections()[0]
      return if selection is null
      selection.selectToEndOfLine() if selection.isEmpty()
      {start, end} = selection.getBufferRange()
      selectionText = editor.getTextInRange([start, end])
      @killRing.push(selectionText)
      selection.delete()
      console.log 'KR: kill-line'

  yank: ->
    atom.workspace.getActiveTextEditor()?.insertText @killRing.peek()
    console.log 'KR: yanked'

  yankPop: ->
    console.log 'KR: yank-pop'

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
