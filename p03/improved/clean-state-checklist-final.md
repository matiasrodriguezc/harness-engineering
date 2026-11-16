# Clean State Checklist -- Project 03

## Build Verification

- [ ] `npm install` completes without errors
- [ ] `npm run check` passes with zero TypeScript errors
- [ ] `npm run build` produces dist/ output

## Feature Verification

- [ ] Window launches with correct dimensions and dark theme
- [ ] Document list shows imported documents with empty state
- [ ] Import button opens file picker, imports .txt and .md files
- [ ] Document detail shows metadata: title, filename, size, import date, word count, line count, file type
- [ ] "View Content" button loads and displays full document text
- [ ] "Show Chunks" button displays chunked content with metadata
- [ ] "Index Document" button triggers chunking and updates status
- [ ] StatusBar shows index status with color-coded indicator
- [ ] StatusBar shows indexed document count and total chunk count
- [ ] Question panel accepts questions and returns answers
- [ ] Answers include citations with document title, chunk index, and excerpt
- [ ] Answers include confidence scores (0.85 with citations, 0.30 without)
- [ ] Documents persist across app restarts
- [ ] Delete button removes document and associated data

## Scope Control Verification

- [ ] feature_list.json shows all features at "pass"
- [ ] Each feature has evidence describing what was implemented
- [ ] No feature has status "fail" or "not-started"
- [ ] AGENTS.md contains one-feature-at-a-time policy
- [ ] Feature dependencies are documented and respected

## Code Quality

- [ ] No `any` types without explanatory comments
- [ ] All exports are named exports
- [ ] IPC channels defined in src/shared/types.ts only
- [ ] Renderer never imports Node.js modules
- [ ] Services never import renderer code
- [ ] All new files follow existing conventions

## Documentation

- [ ] docs/ARCHITECTURE.md updated with chunking pipeline and Q&A flow
- [ ] docs/PRODUCT.md updated with new features
- [ ] session-handoff.md filled out
- [ ] claude-progress.md has session logs
