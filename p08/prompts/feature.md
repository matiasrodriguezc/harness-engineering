# Feature: export the conversation as Markdown

`window.knowledgeBase.conversation.export()` returns a Markdown string with every question and answer in the conversation, in order, each answer followed by its citations (document title and excerpt). An empty conversation returns a Markdown document that says there are no questions yet. The question panel has a button with aria-label 'Export conversation' that saves that Markdown to a file chosen by the user.
