KillRing = require '../lib/kill-ring'
path = require 'path'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "KillRing", ->
  [editor, editorView, activationPromise] = []

  beforeEach ->
    expect(atom.packages.isPackageActive('kill-ring')).toBe false
    atom.project.setPaths([path.join(__dirname, 'fixtures')])
    waitsForPromise ->
      atom.workspace.open('1.txt')

    runs ->
      editor = atom.workspace.getActiveTextEditor()
      editorView = atom.views.getView(editor)
      activationPromise = atom.packages.activatePackage('kill-ring')
      activationPromise.fail (reason) ->
        throw reason

  describe "kill-line", ->
    it "should kill line", ->
      editor.setCursorBufferPosition [0, 0]
      atom.commands.dispatch editorView, 'kill-ring:kill-line'
      expect(editor.getText()).toEqual('\nabcdefghij\nABCDEFGHIJ\n9876543210\nzyxwvutsrq\nZYXWVUTSRQ')
