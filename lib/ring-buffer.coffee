module.exports = class RingBuffer

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
        return nil
      else
        return _buffer[_current]

    @peekback = ->
      if _current < 0
        return nil
      else if _current is 0
        _current = _buffer.length - 1
        return _buffer[_current]
      else
        _current -= 1
        return _buffer[_current]

    normalize = ->
      if (_buffer.length is _size) and (_current > 0)
        newBuffer = _buffer[(_current + 1)..].concat(_buffer[0.._current])
        _buffer = newBuffer

    @getSize = -> _size
    @setSize = (newSize) ->
      normalize()
      if newSize < _buffer.length
        _buffer = _buffer[(_buffer.length - newSize)..]
