# Grammar patterns to catch

These are sentence-construction habits that make prose read as machine-written. Each pattern has a name, real examples that shipped in drafts, and the fix. A sentence can break several at once, so check each pattern separately.

The test for every sentence: would a careful human engineer say it this way out loud to a colleague? If it sounds like a riddle, a legal clause, or a translation, rewrite it.

## 1. Negated object

A sentence that hangs its meaning on "no", "none", or "nothing" as the object of a verb. The reader has to build the thing and then cancel it.

- Bad: "The jabberwock admits no slimer."
- Bad: "Metric attributes still carry none."
- Bad: "`EVENT_TYPES` has no type for one."
- Bad: "The night gets no rows unless every EVE file reads."
- Fix: say what does happen, with a real verb. "The jabberwock keeps slimers out." "Metric attributes hold only IDs and counts." "A night with an unreadable EVE file fails."

## 2. Pro-form echo

A second clause that points back at the first with "doing so", "so", "it", "this", "that", "the same", or "one", usually to restate it or give it a cause. Often the first clause is negated, so the echo points at something that never happens.

- Bad: "The jabberwock admits no slimer, and the rule prevents it from doing so."
- Bad: "Synthetic EVE files now do the same."
- Bad: "so it can't read one correctly yet"
- Fix: name the thing again, or merge the two clauses into one plain statement. "The rule keeps slimers out of the jabberwock."

## 3. Abstract verb on a thing

An inanimate subject with a vague verb such as "admits", "carries", "holds", "keeps", "takes", "gives", "gets", "lands", "fills", or "sees", where a person or the code really does something specific.

- Bad: "EVE gets 0 for hypopneas."
- Bad: "A used night with no machine AHI gives `mismatch`."
- Bad: "so the test can see them go"
- Fix: put the real actor first with a concrete verb. "The machine writes a duration of 0 for hypopneas." "`ahiCheck` returns `mismatch` for a used night with no machine AHI."

## 4. Stacked contact clause

A relative clause with its "that" or "which" left out, attached to a noun. The reader parses the noun as the subject of what follows and has to back up.

- Bad: "A label no event type matches."
- Bad: "with the header the readiness check read"
- Bad: "the rule set `ruleSetFor` picks"
- Fix: put "that" back, or rebuild the sentence around the actor. "An EVE label that airway doesn't recognize." "`edf` is the header that the readiness check read."

## 5. Noun pile

A string of nouns and possessives that names a thing by its relations instead of saying what it is.

- Bad: "the AHI check behind its `ahi_check`"
- Bad: "How the AHI airway computes from the night's events compares with the machine's."
- Bad: "the AHI check's outcome", "the night's row's sessions"
- Fix: say what the thing is in a plain phrase, with a verb if needed. "the result of the AHI check", "whether airway's AHI matches the machine's".

## 6. Verbless description

A doc comment or sentence that's only a noun phrase. It names a value when the reader needs to know what happens.

- Bad: "`files` with each EVE file's bytes passed through `edit`."
- Bad: "One EVE file's annotations. A header-only file has none."
- Bad: "Events as ingest reads them from EVE."
- Bad, on a type: "The unit and decimals of a dataset column that holds a machine signal."
- Bad, on a field: "The home time zone." "Each scanned file, sorted by readiness."
- Bad, a verbless first sentence with a full sentence after it: "The reason identification failed. Only `provider_unavailable` is a server error."
- Fix: start with a verb. "Returns `files` with `edit` applied to every EVE file's bytes." "Extends `ColumnUnit` with the dataset and column that store a machine signal."

This pattern is the easiest to miss, because a noun phrase is the usual style for a comment on a type, a field, or a constant, and it reads as fine. Check the first sentence of every doc comment by itself, including one-line comments on fields. A later sentence with a verb doesn't excuse a verbless first one. Pick the verb that says what the thing is or does ("Maps", "Extends", "Lists", "Returns"); don't reach for the same stock verb each time.

## 7. Telegraphese

Articles, verbs, or subjects dropped to save words, so the sentence reads like a headline or a note to self.

- Bad: "Labels match whatever their case."
- Bad: "to the second EVE keeps"
- Fix: write the full sentence. "Label matching ignores case."

## 8. Pronoun pileup

Several "its", "their", or "it" in one sentence pointing at different nouns, or a pronoun whose noun is a sentence or more back.

- Bad: "Reads a night's EVE files, places their events in its sessions, and builds its row."
- Bad: "Label matching ignores case. It drops "Recording starts"…" ("It" is now label matching.)
- Fix: repeat the noun. "places the events in the night's sessions, and builds the night's row."

## 9. Dangling "which"

A "which" that could point at the last noun or at the whole clause before it.

- Bad: "`duration` is how long it lasted in seconds, which shapes the flow and pressure."
- Bad: "`ts` is its end when the machine writes a duration of 0, which makes `duration` null."
- Fix: split the sentence and name the subject. "The duration shapes the flow and pressure."

## 10. Appositive read as a list item

An appositive set off by commas in a sentence that also has a list or a series of verbs, so it reads as one more item.

- Bad: "reads a night's EVE files, the machine's event files, and turns each annotation into a row."
- Bad: "the row starts at the onset, the event's end."
- Fix: use "which" with a verb. "reads a night's EVE files, which hold the events the machine scored, and turns…"

## 11. Misplaced modifier

A modifier next to the wrong word (Strunk rule 16).

- Bad: "compares airway's count with the machine's AHI in whole tenths"
- Bad: "which only drops float noise from a value stored in 0.1 steps"
- Bad: "obstructive, central, and unclassified apneas and hypopneas" ("unclassified" seems to cover hypopneas.)
- Fix: move the modifier next to its word, or split the sentence.

## 12. Hidden "respectively"

Two subjects paired with two predicates in one clause, leaving the reader to match them up.

- Bad: "`ahi_check` and `rule_set` come from the next section and from `ruleSetFor`."
- Fix: one clause each.

## 13. Loose clause chain

Clauses strung together with "which… because… so…" until one sentence carries three ideas (Strunk rule 14).

- Bad: "Ingest skips CSL files, which hold Cheyne-Stokes periods, because airway has no sample CSL file with a period in it, so it can't read one correctly yet."
- Fix: one idea per sentence.

## 14. Restatement

A sentence or clause that says the one before it again in other words.

- Bad: "If an EVE file fails, the night fails. The night gets no rows unless every EVE file reads."
- Fix: delete the repeat.

## 15. Colon setup

A lead-in, a colon, then the real content, as a reveal.

- Bad: "One night's inputs: its STR.edf day, its ready EVE files, and its sessions."
- Bad: "Span events and warn logs for what scoring found: unknown labels and an AHI mismatch."
- Fix: one sentence with a verb. A colon that introduces a list, code, or a diagram is fine.

## 16. Corrective antithesis

"X, not Y", or "not X but Y", where nobody claimed Y.

- Bad: "A config check, not a gate."
- Fix: say what X is and does.

## 17. Denial sentence

A sentence about what something doesn't do or have.

- Bad: "There's no union." "Touches no filesystem."
- Fix: state the positive fact. Pattern 1 is the same habit inside a sentence.

## 18. Flourish and figurative verb

An idiom, understatement, or loose verb in place of the plain fact.

- Bad: "That costs nothing worth fixing." "The gate fails open." "so logs can say what the data says"
- Fix: give the fact. "EVE files are a few KB, so reading them twice is cheap."

## 19. Literary verb for software

Code described with a verb or noun from human life, where reference documentation has a standard dry term. This is the pattern rewrites break most often, because the literary verb is concrete and active, so it passes patterns 3 and 18.

- Bad: "The server answers every failure with a JSON body." "airway never answers 401."
- Bad: "the refusal", "refuses a file with two headers"
- Bad: "The error message names the host." "the folder it names as its data folder"
- Bad: "A night keeps its date." "A note keeps its snapshots."
- Bad: "a date known only to the month", "two spellings of the same query", "the limit leaves room for both", "the model draws a duration"
- Fix: use the term the API, protocol, or language uses: returns, responds with, rejects, throws, logs, includes, contains, stores, sets, reads, writes, validates, generates. "The server responds to a failed verification with a JSON body." "The error message includes the host." "A date with month precision." "The model generates a duration."

## 20. List written as prose

Three or more parallel conditions, cases, steps, or fields packed into one sentence or a run of sentences.

- Bad: "A night is ready when its STR day is closed, every EVE file has a full header, each BRP file's size matches its header, and the folder has been quiet for a minute."
- Fix: a lead-in sentence and a bulleted list, one item per condition. Number the items when order matters. Two items stay a sentence.

## 21. Unrelated facts joined

Clauses joined with "and", "so", or a semicolon when the second doesn't follow from the first, or a comment that lists facts without saying how they relate.

- Bad: "The card holds one folder per night, and the header is 256 bytes."
- Bad: "Sessions are ordered by start, so a note belongs to one night." (The second clause isn't a consequence of the first.)
- Fix: give each fact its own sentence, in the order the reader needs. Keep "so" and "because" for a real cause. If a fact has no bearing on the code it sits on, cut it (see pattern 23).

## 22. Coined term

A word the draft invented for a project concept and uses as if the reader knows it.

- Bad: "each lane's buckets", "the draw for this night", "the household's notes"
- Fix: use the name the code or the domain already has, or describe the thing. "each signal's buckets", "the values generated for this night".

## 23. Sentence that should be cut

A sentence no rewrite improves, because the reader doesn't need it where it is. Report it with the fix "cut" and no rewrite.

- It restates what the next line of code, the type, or the name already says. "Reads config from `process.env`." "A metric can't be grouped by."
- It documents another system's behavior that this code doesn't control. "Only Pomerium answers 401." "The kubelet probes this path."
- It explains a behavior of some other module, which that module's own comment already covers.
- It tells a test's reader what the test asserts, in a helper or fixture.
- Fix: cut it. If one clause is worth keeping, keep only that clause.
