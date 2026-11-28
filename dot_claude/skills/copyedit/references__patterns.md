# Grammar patterns to catch

These are sentence-construction habits that make prose read as machine-written. Each pattern has a name, bad examples (most from real drafts), and the fix. Patterns 1 to 28 apply to single sentences, and patterns 29 and 30 apply to paragraphs. A sentence can break several patterns at once, so check each pattern separately.

## 1. Negated object

A sentence that uses "no", "none", or "nothing" as the object of its verb. The reader has to build the thing and then cancel it.

- Bad: "The jabberwock admits no slimer."
- Bad: "Metric attributes still carry none."
- Bad: "`EVENT_TYPES` has no type for one."
- Bad: "The night gets no rows unless every EVE file reads."
- Fix: say what does happen, with a real verb. "The jabberwock keeps slimers out." "Metric attributes hold only IDs and counts." "A night with an unreadable EVE file fails."

## 2. Pro-form echo

A second clause that points back at the first with "doing so", "so", "it", "this", "that", "the same", or "one", usually to restate the first clause or to explain why the first clause is true. Often the first clause is negated, so the echo points at something that never happens.

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

A doc comment or sentence that's only a noun phrase. It names a value when the reader needs to know what the code does.

- Bad: "`files` with each EVE file's bytes passed through `edit`."
- Bad: "One EVE file's annotations. A header-only file has none."
- Bad: "Events as ingest reads them from EVE."
- Bad, on a field: "Each scanned file, sorted by readiness." ("Sorted by readiness" describes what code does to the files, so the comment should say which function sorts them.)
- Fix: start with a verb. "Returns `files` with `edit` applied to every EVE file's bytes."

A noun phrase is fine on a type, a field, or a constant when it only says what the value is. These comments are correct:

- On a type: "The unit and decimals of a dataset column that stores a machine signal."
- On a field: "The home time zone." "The reason identification failed. Only `provider_unavailable` is a server error."

If the comment also says what code does to the value, such as sorting, filtering, or converting it, describe that step in a sentence with a verb.

On a function or method, check the first sentence of every doc comment by itself. A later sentence with a verb doesn't excuse a verbless first one. Pick the verb that says what each function does ("Maps", "Extends", "Lists", "Returns"), and use different verbs across a file.

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

Clauses strung together with "which… because… so…" until one sentence contains three ideas (Strunk rule 14).

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

A contrast with a claim nobody made: "X, not Y", "not X but Y", "Y rather than X", or "not only X but also Y". The contrast can span two sentences: "It isn't a cache. It's a lookup table."

- Bad: "A config check, not a gate."
- Bad: "Rather than adding a new parser, this reuses the existing one."
- Bad: "The fix improves not only latency but also memory use."
- Fix: say what X is and does. "This reuses the existing parser." "The fix cuts latency and memory use."

Keep the contrast when the reader would otherwise assume Y, such as a common misreading of an API.

## 17. Denial sentence

A sentence about what something doesn't do or have.

- Bad: "There's no union." "Touches no filesystem."
- Fix: state the positive fact. Pattern 1 is the same habit inside a sentence.

## 18. Flourish and figurative verb

An idiom, understatement, or loose verb in place of the plain fact.

- Bad: "That costs nothing worth fixing." "The gate fails open." "so logs can say what the data says"
- Fix: give the fact. "EVE files are a few KB, so reading them twice is cheap."

## 19. Literary verb for software

Code described with a verb or noun from human life, where reference documentation has a standard dry term. Rewrites break this pattern more often than any other. A literary verb is concrete and active, so a rewrite that uses one fixes patterns 3 and 18 but breaks this one.

- Bad: "The server answers every failure with a JSON body." "airway never answers 401."
- Bad: "the refusal", "refuses a file with two headers"
- Bad: "The error message names the host." "the folder it names as its data folder"
- Bad: "A night keeps its date." "A note keeps its snapshots."
- Bad: "a date known only to the month", "two spellings of the same query", "the limit leaves room for both", "the model draws a duration"
- Fix: use the term the API, protocol, or language uses: returns, responds with, rejects, throws, logs, includes, contains, stores, sets, reads, writes, validates, generates. "The server responds to a failed verification with a JSON body." "The error message includes the host." "A date with month precision." "The model generates a duration."

## 20. List written as prose

Three or more parallel conditions, cases, steps, or fields packed into one sentence or a run of sentences.

- Bad: "A night is ready when its STR day is closed, every EVE file has a full header, each BRP file's size matches its header, and the folder has been quiet for a minute."
- Fix: a lead-in sentence and a bulleted list, one item per condition. Number the items when order matters. If there are only two items, keep them in one sentence.

## 21. Unrelated facts joined

Clauses joined with "and", "so", or a semicolon when the second doesn't follow from the first, or a comment that lists facts without saying how they relate.

- Bad: "The card holds one folder per night, and the header is 256 bytes."
- Bad: "Sessions are ordered by start, so a note belongs to one night." (The second clause isn't a consequence of the first.)
- Fix: give each fact its own sentence, in the order the reader needs. Keep "so" and "because" for a real cause. If a fact is unrelated to the code that the comment documents, cut it (see pattern 23).

## 22. Coined term

A word the draft invented for a project concept and uses as if the reader knows it.

- Bad: "each lane's buckets", "the draw for this night", "the household's notes"
- Fix: use the name the code or the domain already has, or describe the thing. "each signal's buckets", "the values generated for this night".

## 23. Sentence that should be cut

A sentence that the reader doesn't need where it is. Report it as "cut", without a rewrite.

- It restates what the next line of code, the type, or the name already says. "Reads config from `process.env`." "A metric can't be grouped by."
- It documents another system's behavior that this code doesn't control. "Only Pomerium answers 401." "The kubelet probes this path."
- It explains a behavior of some other module, which that module's own comment already covers.
- In a test helper or fixture, it tells the reader what the test asserts.
- Fix: cut it. If one clause is worth keeping, keep only that clause.

## 24. Copula avoidance

"Serves as", "acts as", "functions as", "stands as", "features", or "offers" where "is" or "has" says the same thing. AI copyeditors make this swap to sound formal, so check your own rewrites for it too.

- Bad: "This module serves as the entry point for the CLI."
- Bad: "The config object features three sections."
- Fix: "This module is the CLI's entry point." "The config object has three sections."

"Acts as" is fine when one thing stands in for another: "The stub acts as the server in tests."

## 25. Trailing "-ing" analysis

A participial phrase that ends a sentence and says why the main clause matters: ", ensuring…", ", allowing…", ", making…", ", enabling…", ", highlighting…". The phrase claims a benefit without saying how the code delivers it, and the reader can't tell what does the ensuring or allowing.

- Bad: "Adds a retry to the upload, ensuring requests succeed under load."
- Bad: "Caches the parsed header, making later reads faster."
- Fix: cut the phrase, or give the effect its own clause with a real subject. "Retries the upload once, so one dropped connection doesn't fail the import." "Caches the parsed header so `readNight` parses it once."

## 26. Change-summary boilerplate

In a commit message or PR body, a sentence that says in general terms what the change kept, avoided, or improved, instead of what it changed. Watch for "preserves", "retains", "keeps the existing", "avoids", "ensures", "improves clarity", "improves consistency", "improves readability", and "addresses review feedback".

- Bad: "Refactors the parser for clarity while preserving existing behavior."
- Bad: "Addresses review feedback."
- Bad: "Improves consistency and readability of the docs."
- Fix: name what changed. "Splits `parse` into `tokenize` and `build`." "Renames `ctx` to `night` in `score.ts`."

In a refactor, one plain sentence that says behavior is unchanged is fine, because the reviewer needs to know it.

## 27. Vague connection

"Associated with", "in connection with", "related to", "linked to", or "tied to" where the draft could state the relationship.

- Bad: "the token associated with the session"
- Bad: "errors related to the EVE parser"
- Fix: say what the relationship is. "the token that `login` issued for the session", "errors that the EVE parser throws".

When the fix is a possessive, check it for pattern 5 (noun pile).

## 28. Reflexive triad

Three adjectives, nouns, or short phrases in a row, added to make a claim sound complete. Often the draft supports only one of the items.

- Bad: "The new loader is faster, safer, and simpler."
- Bad: "Improves reliability, observability, and maintainability."
- Fix: keep the items you can support, and give the fact for each. "The new loader reads the header once instead of three times."

Three distinct items that each state a fact are fine. Pattern 20 says when three or more items belong in a bulleted list.

# Paragraph patterns

These patterns appear only across several sentences, so check them on a whole paragraph, doc comment block, or commit or PR body.

## 29. Elegant variation

Two or more words for the same thing in one draft, so the reader wonders whether they're different things.

- Bad: "night", then "session", then "recording", all for one `Night`.
- Bad: "The handler validates the token. If the credential has expired, it returns 401."
- Fix: pick one word, usually the name the code uses, and repeat it.

A pronoun for a noun in the same sentence is fine (see pattern 8).

## 30. Even rhythm

Four or more consecutive sentences of about the same length that use only periods and commas. Each sentence can be clean on its own, but the paragraph still reads as machine-written. The writing rules ask for short sentences, so writers who follow them often make every sentence the same short length.

- Bad: "The loader reads every EVE file in the night's folder. It parses the header before it reads any annotations. Each annotation becomes one row in the events table. The rows are sorted by onset before the loader returns them."
- Fix: combine sentences that share a subject, or let one sentence run longer to carry the detail. "The loader reads every EVE file in the night's folder. For each file, it parses the header and then turns every annotation into a row in the events table. It sorts all the rows by onset before it returns them."

Report the whole paragraph with a rewrite. Don't fix this pattern by chaining clauses into one long sentence (pattern 13).
