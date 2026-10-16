> Authoring guidance for interaction-pattern-library.md. Load only the part covering the section currently being authored — not the whole file at once.

# Interaction Pattern Library — Guidance Index

The guidance for this template is split by major section so consumers can load
one part at a time. Read the file matching the section you are currently
authoring — never all of them at once.

| Template Section | Guidance File |
|------------------|---------------|
| Standard Control Patterns (Button variants, Toggle, Slider, Select / Combobox, List Item, Data Table, Modal Dialog, Confirmation Dialog, Toast / Notification, Tooltip, Progress Bar / Meter, Input Field, Tab Bar, Scroll Container / Pagination) | `.claude/docs/templates/guidance/interaction-pattern-library-guide-standard-controls.md` |
| Navigation Patterns + Feedback and Loading Patterns (Screen Push / Pop / Replace, Focus Management, Escape / Cancel, Loading State, Empty State, Error State, Success Confirmation, Optimistic UI, Offline / Degraded) | `.claude/docs/templates/guidance/interaction-pattern-library-guide-navigation-feedback.md` |

**SaaS-Specific Patterns** (Form & Validation, Wizard, Filter Bar, Bulk Selection,
Inline Edit, Command Palette, File Upload, Plan Gate / Upgrade Prompt, Quota
Meter, Permission-Denied, Async Job Status, Sensitive Value Reveal, Banner) have
no separate guidance file: the pattern stubs in the template already carry the
When to Use, states, accessibility and implementation hints. Specify them in the
template itself and promote a pattern to a guidance file only if it grows beyond
a screen of text.

Each guidance file contains the full reference specification for its patterns —
When to Use / When NOT to Use rationale, complete state tables with timing
values, accessibility requirements, and per-stack implementation notes (web,
Android, iOS). Use them as the worked-example source when filling the
corresponding skeleton stubs in the template. The Pattern Catalog Index,
Animation Standards, Feedback Channels, Direction and Locale Standards, and Open
Questions sections remain in the template itself.

Visual styling (colours, radii, type, shadows) is out of scope for every file in
this set — it lives in `DESIGN.md` (impeccable). These files define behaviour,
states, semantics and accessibility.
