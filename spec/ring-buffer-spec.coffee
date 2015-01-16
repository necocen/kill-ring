RingBuffer = require '../lib/ring-buffer'

describe "RingBuffer", ->
	[buffer] = []

	beforeEach ->
		buffer = new RingBuffer([], 4)

	it "should save text", ->
		buffer.push 'neko'
		expect(buffer.peek()).toEqual 'neko'
