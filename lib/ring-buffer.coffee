module.exports = class RingBuffer

  constructor: (buffer, size) ->
    _size = size
    _buffer = buffer
    _head = _buffer.length - 1
    _current = _head

    @push = (text) ->
      if _head >= (_size - 1)
        _head = 0
      else
        _head += 1
      _buffer[_head] = text
      _current = _head

    @peek = ->
      if _current < 0
        return null
      else
        return _buffer[_current]

    @peekback = ->
      if _current < 0
        return null
      else if _current is 0
        _current = _buffer.length - 1
        return _buffer[_current]
      else
        _current -= 1
        return _buffer[_current]

    @normalize = ->
      if (_buffer.length >= _size) and (_current > 0)
        newBuffer = _buffer[(_head + 1)..(_size - 1)].concat(_buffer[0.._head])
        _buffer = newBuffer
        if _current <= _head
          _current = _size - 1 - (_head - _current)
        else
          _current = (_current - _head) - 1
        _head = _size - 1


    @getSize = -> _size
    @setSize = (newSize) ->
      @normalize()
      if newSize < _buffer.length
        _buffer = _buffer[(_buffer.length - newSize)..]
        _head = newSize - 1
      _current = _head
      _size = newSize
