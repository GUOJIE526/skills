# Skills

A collection of agent skills. Each skill is a directory the agent loads to perform one kind of task.

## Language

### Skill anatomy

**Skill**:
A directory containing a `SKILL.md` plus whatever assets and scripts it needs. The unit this repo distributes.
_Avoid_: command, plugin, tool

**Build script**:
A per-platform script that turns an agent-written input file into a finished artifact. It only moves text around — it holds no rules about what the input may contain.
_Avoid_: generator, compiler

**Renderer**:
The generic HTML file a build script splices data into. It owns every rule about what the data may contain, and it is never edited per use.
_Avoid_: template, view

### Matt grill questionnaire

**Grill**:
An interview that pushes the user through a design tree until nothing is left silently assumed.

**Payload**:
The JSON file the agent writes to describe one questionnaire — its title, recap, and questions. The only thing that changes between runs.
_Avoid_: config, data file, input

**Questionnaire**:
The generated HTML page a user answers. Lives in the OS temp directory, never in a repository.

**Recap**:
Decisions the user has already made, shown as one-line reminders. Never a place to park an open decision.

**待確認**:
A question the user left blank. It stays open — a recommendation counts only once the user clicks it or confirms it in chat.
_Avoid_: pending, unanswered, defaulted
