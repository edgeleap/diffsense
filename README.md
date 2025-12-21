<div align="center">
  <img src="github_vector_readme_logo.svg?raw=true" alt="Logo" width="100" height="100">
  <h3 align="center">DiffSense</h3>
  <p align="center">
    AI-powered git commit messages running locally on your Mac with Apple Intelligence.
    <br/>
    <br/>
    <span style="display:inline-block; margin-right:8px;">
      <a href="" target="_blank" rel="noopener noreferrer"><img
        src="https://img.shields.io/badge/macOS-Tahoe%2026-000000?style=for-the-badge&logo=apple&logoColor=white"
        alt="os"
      /></a>
    </span>
    <span style="display:inline-block;">
      <a href="" target="_blank" rel="noopener noreferrer"><img
        src="https://img.shields.io/badge/Apple%20Silicon-ARM64-0071e3?style=for-the-badge&logo=apple&logoColor=white"
        alt="cpu"
      /></a>
    </span>
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

## Troubleshooting

**"Command not found"**
- Restart your terminal or run `source ~/.zshrc`

**"No git repository found"**
- Run `git init` or navigate to a git repository

**Model not responding**
- Ensure macOS Tahoe 26 is installed and Apple Intelligence is enabled in System Settings

## License

MIT © EdgeLeap
 
