RingBuffer = require '../lib/ring-buffer'

describe "RingBuffer", ->
	[buffer] = []

	beforeEach ->
		buffer = new RingBuffer([], 4)

	describe "push", ->
		it "should save text", ->
			buffer.push 'neko'
			expect(buffer.peek()).toEqual 'neko'

		it "should save some texts", ->
			buffer.push '111'
			buffer.push '222'
			buffer.push '333'
			buffer.push '444'
			expect(buffer.peek()).toEqual '444'
			expect(buffer.peekback()).toEqual '333'
			expect(buffer.peekback()).toEqual '222'
			expect(buffer.peekback()).toEqual '111'

		it "should be restricted with buffer size", ->
			buffer.push '111'
			buffer.push '222'
			buffer.push '333'
			buffer.push '444'
			buffer.push '555'
			expect(buffer.peek()).toEqual '555'
			expect(buffer.peekback()).toEqual '444'
			expect(buffer.peekback()).toEqual '333'
			expect(buffer.peekback()).toEqual '222'
			expect(buffer.peekback()).toEqual '555'

		it "resets buffer position", ->
			buffer.push '111'
			buffer.push '222'
			buffer.push '333'
			expect(buffer.peek()).toEqual '333'
			expect(buffer.peekback()).toEqual '222'
			buffer.push '444'
			expect(buffer.peek()).toEqual '444'
			expect(buffer.peekback()).toEqual '333'
			expect(buffer.peekback()).toEqual '222'
			expect(buffer.peekback()).toEqual '111'

	describe "peek", ->
		it "shows pushed texts periodically", ->
			buffer.push '111'
			buffer.push '222'
			expect(buffer.peek()).toEqual '222'
			expect(buffer.peekback()).toEqual '111'
			expect(buffer.peekback()).toEqual '222'
			expect(buffer.peekback()).toEqual '111'

	describe "setSize", ->
		it "preserves buffer state on expanding", ->
			buffer.push '111'
			buffer.push '222'
			buffer.push '333'
			buffer.setSize 8
			expect(buffer.peek()).toEqual '333'
			expect(buffer.peekback()).toEqual '222'
			expect(buffer.peekback()).toEqual '111'
			expect(buffer.peekback()).toEqual '333'

		it "truncates buffer on shrinking", ->
			buffer.push '111'
			buffer.push '222'
			buffer.push '333'
			buffer.setSize 2
			expect(buffer.peek()).toEqual '333'
			expect(buffer.peekback()).toEqual '222'
			expect(buffer.peekback()).toEqual '333'
			expect(buffer.peekback()).toEqual '222'
