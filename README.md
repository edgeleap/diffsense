<div align="center">
  <img src="github_vector_readme_logo.svg" alt="Logo" width="100" height="100">
  <h3 align="center">DiffSense</h3>
  <p align="center">
    AI-powered git commit messages running locally on your Mac with Apple Intelligence.
    <br/>
    <br/>
    <a href="https://github.com/edgeleap/diffsense/releases" target="_blank" rel="noopener noreferrer"><img src="https://img.shields.io/github/v/release/edgeleap/diffsense?color=FADADD&style=for-the-badge" alt="latest release" /></a>
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

1. In terminal: `curl https://edgeleap.github.io/diffsense.sh`  
2. Download the [Shortcut](https://www.icloud.com/shortcuts/eb12c7d8e47742c9b32ddc1f277fc8bc) 
3. Stage your cahnges and call `diffsense` in your terminal

**Example git commit message:**  
```
Add error handling in login flow
Handle missing token case to prevent crash when API response is null.
```

### Customization

**Message style:**
- `diffsense` - Balanced (default)
- `diffsense --verbose` - Detailed explanations
- `diffsense --minimal` - Brief descriptions

**AI models:**
- `--afm` - On-device AFM 3B (default, private)
- `--pcc` - Private Cloud Compute (more capable)
- `--gpt` - ChatGPT 4o (best quality, quota limits)

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
- Improve diff algo, chunking etc (V1)
- BYO prompt instruction via flag + macro for easy access (V1)
- Add support for BYO API keys for Anthropic, Gemini, OpenAI etc (V2)

## License

MIT © EdgeLeap
 
