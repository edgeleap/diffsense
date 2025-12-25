<div align="center">
  <img src="github_vector_readme_logo.svg" alt="Logo" width="100" height="100">
  <h3 align="center">DiffSense</h3>
  <p align="center">
    AI-powered git commit messages running locally on your Mac with Apple Intelligence.
    <br/>
    <br/>
    <a href="https://github.com/edgeleap/diffsense/releases" target="_blank" rel="noopener noreferrer"><img src="https://img.shields.io/github/v/release/edgeleap/diffsense?color=CFE9F3&style=for-the-badge" alt="latest release" /></a>
    <a href="https://github.com/edgeleap/diffsense/releases" target="_blank" rel="noopener noreferrer"><img src="https://img.shields.io/github/downloads/edgeleap/diffsense/total?color=CDE8C4&style=for-the-badge" alt="total downloads" /></a>
  </p>
</div>

## Why DiffSense

- **Private**: Your code never leaves your machine - runs entirely on Apple Silicon
- **Fast**: Generates messages in seconds using AFM 3B model
- **Smart**: Handles changes from single files to 100+ file refactors
- **Free**: No subscriptions, API quotas, or cloud dependencies

## Requirements

- macOS Tahoe 26 or later
- git 2.50.1 or later
- Apple Silicon (M1/M2/M3/M4/M5)

### Install

1. In terminal: `curl -fsSL https://edgeleap.github.io/install.sh | bash`  
2. Download the [Diffsense.shortcut](https://github.com/edgeleap/diffsense/releases/latest/download/Diffsense.shortcut)
3. Stage your cahnges and call `diffsense` in your terminal

**Example git commit message:**  
```
Add error handling in login flow
Handle missing token case to prevent crash when API response is null.
```

### Customization

**Getting help:**
- `diffsense --help` - Show all available options and usage information

**Message style:**
- `diffsense` - Balanced (default)
- `diffsense --verbose` - Detailed explanations
- `diffsense --minimal` - Brief descriptions
- `diffsense --byo '~/team_rules.md'` - Custom prompt instruction

**AI models:**
- `--afm` - On-device AFM 3B (default, private)
- `--pcc` - Private Cloud Compute (more capable)
- `--gpt` - ChatGPT 4o (best quality, quota limits)

**Custom prompt instructions:**
- `--byo <file>` - Use custom commit message rules from a file
  - Examples: 
    `diffsense --byo=samplerules.md`
    `diffsense --byo=samplerules.md --minimal`
    `diffsense --byo=samplerules.md --verbose`
    `diffsense --byo=samplerules.md --minimal --gpt`
    `diffsense --byo=samplerules.md --verbose --nopopup`
  - See [cstm_cmt_msg_rules.md](cstm_cmt_msg_rules.md) for an example template

**Workflow:**
- `--nopopup` - Skip edit dialog (useful for agents)

**Terminal macros**
- Add + diffsense + Push: `upload` install: `echo "alias upload='git add . && diffsense && git push'" >> ~/.zshrc`
- Add + diffsense: `commit` install: `echo "alias commit='git add . && diffsense'" >> ~/.zshrc`

## Troubleshooting

**"Command not found"**
- Restart your terminal or run `source ~/.zshrc`

**"No git repository found"**
- Run `git init` or navigate to a git repository

**Model not responding**
- Ensure macOS Tahoe 26 is installed and Apple Intelligence is enabled in System Settings

## Roadmap

- BYO prompt instruction via flag + macro for easy access (V1)
- Improve diff algo with chunking (V2)
- Add support for BYO API keys for Anthropic, Gemini, OpenAI etc (V2)

## License

MIT © EdgeLeap
