# AGENTS.md

## Working defaults
- Make the smallest change that solves the task.
- Prefer modifying existing code over adding new files.
- Do not add dependencies unless clearly necessary.
- Avoid broad refactors unless explicitly requested.
- Preserve existing naming, structure, and local patterns.
- Before running npm install or adding any package, check the exact version for known CVEs using npm audit. Only install if the version is clean. Pin the exact version in package.json.

## Process
- Start by identifying the narrowest files and functions involved.
- State assumptions when requirements are ambiguous.
- Validate with the smallest relevant command first, then broader validation if needed.
- If a command fails, report the failure plainly and do not invent causes.

## Coding style
- Prefer explicit code over clever code.
- Keep functions focused and reasonably small.
- Do not swallow errors silently.
- Add comments only where intent is not obvious.

## Blog editing style
- For blog edits requested in chat, return only the revised passage in a markdown code block unless explicitly asked for explanation.
- Do not add agreement, apology, praise, alternatives, or commentary unless asked.
- Keep the voice first-person, casual, and journal-like.
- Preserve the original meaning, specificity, and level of enthusiasm.
- Improve flow without adding a tidy lesson, takeaway, joke, punchline, or reader-facing advice.
- Avoid review-site, marketing, sales, or "engagement" language.
- Avoid performative skepticism and self-important framing.
- No curly punctuation - ASCII only
- Do not invent feelings, memories, motivations, intentions, or personal growth.
- Let affection come through in specific details. Avoid generic declarations like "I've always loved" or "I keep coming back to."
- Assume an informed reader. Skip definitions, obvious visual descriptions, and background that the narrative does not need.
- Connect ideas into a narrative. Do not simply turn each requested topic into a separate paragraph.
- Do not impose a lesson, takeaway, inspirational arc, or tidy conclusion.
- Avoid marketing language, exaggerated significance, clever punchlines, and sentences written to sound quotable.
- Preserve the original meaning, specificity, and level of enthusiasm.
- Use ASCII punctuation only.

## Final output
- Summarize what changed.
- List validation performed and result.
- Note assumptions, risks, and anything left unverified.
