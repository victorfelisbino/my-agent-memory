# Black Widow: Salesforce Debug Log Analyzer (.NET/Avalonia)

## Project Overview
- **Name**: Salesforce Debug Log Analyzer (commercial name: Black Widow)
- **Company**: Black Widow Team
- **Tech Stack**: .NET 8+ (C#), Avalonia UI, MVVM
- **Primary Value**: Groups related Salesforce debug logs from single transactions and visualizes complete user experience journey
- **Status**: Multi-version release with CI/CD, update service, "Go Live" (PRO) features
- **Location**: /Users/victorfelisbino/Documents/salesforce-debug-log-analyzer

## Architecture Observations

### UI Framework: Avalonia (WPF-like cross-platform)
- XAML-based markup language (.axaml files)
- Supports Windows, macOS, Linux from single codebase
- MVVM pattern with view models for each major feature
- Material Design icons via MaterialIcon control

### Core Services
- **UpdateService**: Handles version management and release distribution
- **LogGroupService**: Groups related debug logs by transaction
- **SettingsService**: User preferences and configuration
- **WhatsNewService**: Release notes and feature announcements
- **ConnectionService**: Salesforce OAuth/token management

### Key Views/Features
1. **RawLogTab** - Direct log text display with search
2. **TreeTab** - Hierarchical log structure visualization
3. **TimelineTab** - Chronological log replay
4. **AlertCenterPanel** - Rule-based alert system for log anomalies
5. **ConnectionDialog** - Salesforce org authentication
6. **DebugLevelDialog** - Log level configuration
7. **AlertDetailDialog** - Alert inspection and details

### Performance Constraints (v1.4.13 critical limits)
- **MaxDisplayBytes**: 10 MB hard truncation threshold
- **HighlightCutoffBytes**: 5 MB (above this, disable syntax highlighting)
- Reason: AvaloniaEdit regex highlighter runs per visible line; document buffer copies on every Text= assignment
- Solution: Async loading with CancellationTokenSource, explicit Document instance ownership

## .NET Patterns & Learnings

### UI Responsiveness
- Use Dispatcher.UIThread.Post() with DispatcherPriority for render updates
- Separate async load operations from UI thread (LoadSingleLogAsync, LoadGroupAsync)
- InvalidateMeasure() on TextArea when tab visibility changes to force layout recompute

### MVVM Data Binding
- PropertyChangedEventArgs filtering to only refresh on relevant properties
- SelectedLog, ShowGroupedRawLogs, SelectedLogGroup drive view refresh
- RequestedScrollToLine binding for programmatic navigation

### Resource Management
- CancellationTokenSource lifecycle tied to view attachment/detachment
- OnDetachedFromVisualTree cleanup to prevent memory leaks
- Event handler unsubscription on teardown (never throw from cleanup)

### Text Editor Integration (AvaloniaEdit)
- SearchPanel.Install(Editor) for Ctrl+F with match count
- SyntaxHighlighting loaded from custom SalesforceLogHighlighting
- TextArea.Foreground must be explicitly set on dark themes (AvaloniaEdit 11.3 bug: default tokens render invisible)
- Document swapping (not Text=) to avoid stuck/empty document state

## Salesforce Integration Patterns

### Connection Management
- OAuth token-based authentication with saved connection history
- Recent connections persisted with LastUsed timestamps
- Manual token fallback for advanced users (Instance URL + Access Token)
- Environment toggle (Production vs Sandbox) in connection dialog

### Log Analysis
- Grouping by transaction ID to correlate child logs from single user action (e.g., saving a Case → 13 logs)
- User journey replay showing complete execution flow
- Alert rules for anomaly detection (e.g., governor limits, performance thresholds)
- Multi-tab view: raw text, tree hierarchy, timeline, alert summary

### Release Features
- "Go Live" feature (PRO tier): real-time log streaming without downloads
- Beta badge overlay for features in testing
- Staged rollout with update service

## Release & DevOps

### CI/CD Pipeline
- GitHub workflows for CI (`.github/workflows/ci.yml`)
- Automated release builds (`.github/workflows/release.yml`)
- Unit tests for core services (UpdateServiceTests, LogGroupServiceTests, TreeFilterTests)

### Testing
- Service-level unit tests (UpdateService, LogGroupService)
- Filter/selection logic tests
- XAML highlighting tests for log syntax validation

## Known Risks & Mitigations

### Performance
- **Risk**: Large log files (>5 MB) freeze UI during syntax highlighting
- **Mitigation**: Disable XSHD highlighting above 5 MB threshold
- **Long-term**: Incremental/lazy rendering of log display

### Salesforce API Integration
- **Risk**: Rate limits on debug log retrieval during "Go Live" streaming
- **Mitigation**: Batch requests, connection pooling, explicit rate-limit handling in UpdateService

### Cross-Platform Consistency
- **Risk**: Avalonia rendering differences macOS vs Windows
- **Mitigation**: Test on all target platforms before release, use platform-specific font/color overrides sparingly

## Recommended Guardrails for Future .NET/Avalonia Work

1. **Always explicitly own TextEditor.Document** - never rely on XAML construction
2. **Set TextArea.Foreground explicitly** on dark themes - don't assume inheritance
3. **CancellationToken on all async UI operations** - allows teardown cleanup
4. **Test large file performance early** - syntax highlighting is a common bottleneck
5. **Use Dispatcher.UIThread.Post + DispatcherPriority** for layout changes (not synchronous)
6. **Avoid Text= swaps on TextDocument** - use Document instance swapping instead
7. **Capture baseline metrics for v1.x release** - log display speed, memory, CPU on typical (5 MB) and edge case (10 MB+) files

## Next Learning: Chat Session Export
Full analysis of decision-making process, architecture rationale, and problem-solving approach requires exporting chat transcripts from:
- chatSessions: c62e125f, ba5fc33c, 7424fed0, 8a518b47, f0d69435, 42d5af7f
- These contain multi-turn conversations on:
  - Native vs web app market strategy
  - Avalonia framework selection rationale
  - Performance tuning approach
  - Release planning and feature prioritization

**Action**: Export these sessions to markdown/JSON and re-analyze for decision patterns and architectural thinking.
