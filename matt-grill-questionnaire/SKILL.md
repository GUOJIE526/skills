---
name: matt-grill-questionnaire
description: Turn unresolved Matt grill decisions into an HTML questionnaire and open it in the browser.
disable-model-invocation: true
user-invocable: true
---

# Matt Grill Questionnaire

Question surface for a Matt grill. Take the decisions that are still open, write them as a JSON payload, and let the bundled script render and open the questionnaire.

**Do not re-investigate the codebase for this skill.** Everything you need is already in the grill conversation. No git status, no repo scan, no post-build audit — the questionnaire page validates its own payload on load and refuses to render if anything is wrong.

## Workflow

1. **Collect the open decisions.** Use only what the grill has already established. Decisions the user already made go in `recap` as one-line reminders, not as questions.

   `recap` is for what the user confirmed — never park an open decision there because the answer looks obvious to you. If it changes behavior, contract, data, or flow and the user has not ruled on it, it is a question. What you may leave out entirely is anything that changes none of those.

2. **Write the payload.** Save JSON to the scratchpad or temp directory. Traditional Chinese; keep identifiers, paths, commands, and API names as-is.

   **Every string renders as plain text.** HTML is printed, not applied — `<br>` shows up on the page as the four characters `<br>`. The renderer refuses the payload if it finds `<br>`, `<strong>`, `<em>`, `<b>`, `<i>` or `<u>`. To break a thought into parts, add another `context` entry.

   ```json
   {
     "title": "問卷標題",
     "lede": "為什麼需要使用者決定，一句話",
     "storageKey": "matt-grill-questionnaire:<topic>-<YYYYMMDD-HHmmss>",
     "recap": ["已確認的前提，一行一則；沒有就給空陣列"],
     "questions": [
       {
         "id": "q1",
         "title": "一個具體、可判斷的決策問題？",
         "required": true,
         "context": ["現況：DB 十格比例欄位全可 NULL", "契約：儲存時任一為 null 回 400"],
         "scenario": "只填了一格就按儲存，這次該成功還是失敗？",
         "recommendation": "B",
         "options": [
           { "key": "A", "title": "選項 A", "note": "代價與適用條件。" },
           { "key": "B", "title": "選項 B", "note": "它避開了什麼風險。" }
         ]
       }
     ]
   }
   ```

   Per question: a stable `id`, two to four mutually distinguishable options, and a `scenario` that makes the trade-off concrete — a question without a situation is not answerable. `context` is a list of one-fact lines, at most three, and only facts that change the answer. Set `required: false` for implementation preferences. Omit `recommendation` when the evidence does not support one. Order dependent questions after the decision that unlocks them.

   **Writing the payload is the slow part of this skill, and length is the only reason.** You are writing for the person who just sat through the grill, so never restate what they already told you. Stay inside these budgets — a five-question questionnaire should land near 2,000 characters total, and going over is a sign the question is really two questions:

   | 欄位 | 上限 |
   | --- | --- |
   | `lede` | 一句，40 字 |
   | `recap` 每則 | 30 字，最多 6 則 |
   | `title` | 30 字 |
   | `context` 每則 | 40 字，最多 3 則 |
   | `scenario` | 80 字 |
   | 選項 `title` | 20 字 |
   | 選項 `note` | 40 字 |

   `recommendation` is display-only. **A blank question is never auto-resolved**, whatever `required` says — a recommendation only counts once the user clicks it or confirms it in chat. `required` controls how loudly the blank is reported, not whether you may decide it yourself.

3. **Build and open.** One command. It splices the payload into the template, writes the result to the OS temp directory with a timestamped filename, prints the path, then opens it in the browser.

   Use the **absolute path of this skill's own directory** — the grill runs from the user's project, not from here, so a relative `scripts/...` path will not resolve.

   - Windows: `powershell.exe -File "<skill-dir>\scripts\build-questionnaire.ps1" -Data "<payload.json>"`
   - macOS: `sh "<skill-dir>/scripts/build-questionnaire.sh" "<payload.json>"`

   The path is printed before the browser is launched, and a launcher that fails does not fail the build. If you get a warning that the browser could not be opened, say so in one sentence and hand over the printed path — do not retry and do not try another launcher.

   Pass an explicit output path (`-Out` on Windows, second argument on macOS) only when the user asks for one. Never hand-patch the generated HTML — fix the payload and rebuild.

   **The page checks the payload as it loads.** If anything is wrong it renders a list of the problems instead of the questionnaire, so the user hits the error immediately rather than answering half a form. If the user reports that page, fix the payload from the listed problems and rebuild. The checks are: no formatting tags in any string; at least one question; every question has an `id`, a `scenario`, and two or more options; `context`, when present, is an array; ids are unique; every option has `key` and `title`; any `recommendation` matches an option key.

4. **Hand off and stop.** Return the printed path as a clickable link, state that it was opened, and tell the user to answer, click `整理回復 prompt`, then paste the result back. Pause the grill until they reply. If they answer in chat instead, reconcile that with the questionnaire and continue from the resulting decisions.

   When the reply comes back: answers and notes are confirmed. Anything the prompt marks 待確認 stays open — ask about it (one round, batched) rather than assuming; a question answered only by a note means judge from that note, not from your recommendation. Resume the grill once nothing is left open or the user has explicitly accepted the remaining recommendations.

## Files

- `assets/questionnaire-template.html` — the renderer: **payload validation**, styling, progress bar, draft persistence, reply-prompt generation, copy fallback. It is **generic and never edited**; the build script only swaps the `questionnaire-data` JSON block.
- `scripts/build-questionnaire.ps1`, `scripts/build-questionnaire.sh` — escape the payload, splice it in, write to temp, print the path. They only move text around; every rule about payload content lives in the renderer.

Generated questionnaires live in the OS temp directory — never in the repository or the skill directory.
