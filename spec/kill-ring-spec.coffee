KillRing = require '../lib/kill-ring'
path = require 'path'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "KillRing", ->
  [editor, editorView, activationPromise] = []

  beforeEach ->
    atom.project.setPaths([path.join(__dirname, 'fixtures')])
    waitsForPromise ->
      atom.workspace.open('1.txt')

    runs ->
      editor = atom.workspace.getActiveTextEditor()
      editorView = atom.views.getView(editor)
      activationPromise = atom.packages.activatePackage('kill-ring')

  describe "kill-line", ->
    it "should kill line", ->
      editor.setCursorBufferPosition [0, 0]
      atom.commands.dispatch editorView, 'kill-ring:kill-line'
      waitsForPromise -> activationPromise
      runs ->
        expect(editor.getText()).toEqual('\nabcdefghij\nABCDEFGHIJ\n9876543210\nzyxwvutsrq\nZYXWVUTSRQ\n')

    it "should remove linebreak when the cursor is on end-of-line", ->
      editor.setCursorBufferPosition [0, 10]
      atom.commands.dispatch editorView, 'kill-ring:kill-line'
      waitsForPromise -> activationPromise
      runs ->
        expect(editor.getText()).toEqual('0123456789abcdefghij\nABCDEFGHIJ\n9876543210\nzyxwvutsrq\nZYXWVUTSRQ\n')

    it "should do nothing when the cursor is on end-of-file", ->
      editor.setCursorBufferPosition [6, 0]
      atom.commands.dispatch editorView, 'kill-ring:kill-line'
      waitsForPromise -> activationPromise
      runs ->
        expect(editor.getText()).toEqual('0123456789\nabcdefghij\nABCDEFGHIJ\n9876543210\nzyxwvutsrq\nZYXWVUTSRQ\n')
