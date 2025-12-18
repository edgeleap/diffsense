# DiffSense 🧠

> A free git commit message generator powered by Apple Intelligence

![macOS Tahoe 26](https://img.shields.io/badge/macOS-Tahoe%2026-000000?style=for-the-badge&logo=apple&logoColor=white)
![Apple Silicon](https://img.shields.io/badge/Apple%20Silicon-ARM64-0071e3?style=for-the-badge&logo=apple&logoColor=white)
![Git 2.50.0+](https://img.shields.io/badge/git-2.50.0+-F05032?style=for-the-badge&logo=git&logoColor=white)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)](https://opensource.org/licenses/MIT)

### Problem

1. Github desktop AI generator button is great. But your AI quota quickly runs out on free account
2. Writing git messages manually takes too much time, and when rushing: `"Update"`, `"New update"`, `"new new update"` 😅
3. Using Claude Sonnet 4.5, GPT 5.2 etc to create git messages for you is expensive and cumbersom

### Solution

1. DiffSense is a terminal call that creates a AI generated git message for free. 
2. DiffSense uses a bash command, a shortcut and Apple Inteligence to turn a git diff into a clear git message
3. You can use DiffSense with default settings, and it will perform similarly as github desktop AI git message works. You can also customize DiffSense so that it writes git messages in the style you or your team prefers. All git messages are editable before the commit action is called.

### Install

1. In terminal: `curl http://edgeleap.github.io/diffsense.sh` (installs the diffsense bash functions in an alias)
2. Download the [Diffsense Shortcut](https://www.icloud.com/shortcuts/6d93e2d1f09e4e8aa55b78524fb42dae) (this will install the shortcut in your shortcut app)
3. Call `diffsense` in your terminal 👉 A shortcut window with your AI generated git msg pops up, click ok and ✅

**Example git commit message:**  
```
Add error handling in login flow
Handle missing token case to prevent crash when API response is null.
```

<img width="355" alt="img" src="https://github.com/edgeleap/diffsense/blob/main/popup.gif?raw=true">

### Customisation

1. There are 3 different commit message styles: default: `diffsense`, `diffsense --verbose`  `diffsense --minimal`
2. Pick the model you want to use in the shortcut. All are free to use and require no API key or subscriptions and are tied to your CPU or your macOS user account. A) Use the local LLM on your mac, B) Use Apple Intelligence private cloud AI, C) Pick ChatGPT 4o (switches to 4o mini on high usage) 
3. Change the prompt instruction to get git messages the way you want. This is the default prompt instruction
```
TextYou are given a git diff. Write a concise, human-readable git commit message that accurately describes the actual changes.

Rules:
1. Base your message strictly on what is shown in the git diff. Do not invent or guess context.
2. Summarize *what changed* and *why*, only if the reason is directly implied by the diff.
3. Start with a short, imperative title (like “Fix null check in user validator”).
4. Follow with a brief description on the next line if needed (1–3 sentences max).
5. Use clear, factual language. Avoid generic or vague phrases like “update”, “improve”, or “refactor” unless the diff clearly reflects that action.
6. Do NOT include any meta commentary, formatting, bullet points, or explanations about your reasoning.
7. Output only the commit message text: title on the first line, optional description below.

Example format:
Add error handling in login flow\n
Handle missing token case to prevent crash when API response is null.
```

### Gotchas and limitations:

- When there are large git diffs 100s of files etc, DiffSense will first simplify it with local LLM (if available, or use heuristics if not) and then generate the git message based on the AI / Heuristically truncated git diff. This might reduce the fidelity in the git message description, but is nessasery to not hit limits with Apple Inteligence remote AI token limits and quatas.
- Chat GPT 4o switches to 4o mini with high usage (resets every 24h) Bypassing Limits: If you connect a paid ChatGPT Plus account in Settings in macOS, you bypass the Apple Intelligence specific limits and instead use your personal account's significantly higher quotas (up to 5x more GPT-4o messages.
- Chat GPT 4o comes free with any user that has a modern apple computer, and requires no OpenAI subscription etc.
- You can also use your own AI model by adding a shell script in the shortcut that calls any model OpenAI, Claude, Gemini etc. .sh script for OpenAI/Claude/Gemini: [Shell Script](https://gist.github.com/eonist/95d25034c6949c697f77628451640153)
- For updates. call the curl in terminal again and it will download an updated version. New shortcut link will also be added to the github readme / landing page. (Updates will not be frequent, DiffSense should pretty much work as is forever, unless shortcut api's change etc, then update might be required)

### Requirments

- macOS Tahoe 26 
- git 2.50.1+
- Apple Silicon CPU M1 - m5 (When using local LLM)

### Privacy:

- Users that can only use local on-prem LLM's due to restrictions at work etc, can set the model in the shortcut prefs to use Local Apple intelligence LLM (this requires apple silicon cpu (M1-M5)
- For users that prefer Apple Inteligence Private cloud AI. Set this model, in the shortcut app.
- For users that wants the best model for the job and are fine with chatgpts privacy eula. No action required. This is the default setting in the shortcut.
- Google Analytics is used to track installations and website visits (We do not track and will not track any telemetrics from app usage etc)

