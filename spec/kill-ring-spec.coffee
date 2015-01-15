KillRing = require '../lib/kill-ring'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "KillRing", ->
  [activationPromise] = []

  beforeEach ->

  describe "kill-ring", ->
    it "saves killed text", ->
      expect(1).toEqual(1)
      expect(2).toEqual(2)
      KillRing.killRing.push("12345")
      expect(KillRing.killRing.peek()).toEqual("12345")


#      waitsForPromise ->
#        atom.workspace.open()
      #waitsForPromise ->
      #  atom.packages.activatePackage('kill-ring')

#      runs ->
#        console.log 'nekoneko'
#        expect(1).toEqual(1)
#        #KillRing.killRing.push("12345")
#        #expect(KillRing.killRing.peek()).toEqual("12345")
