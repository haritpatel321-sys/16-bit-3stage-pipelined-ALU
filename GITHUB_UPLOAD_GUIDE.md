# GitHub upload guide

## Option A — easiest: GitHub website

1. Create a new repository on GitHub.
2. Suggested name:
   `16-bit-3stage-pipelined-ALU`
3. Choose Public if you want professors/recruiters to see it.
4. Do not upload passwords, API keys or other secrets.
5. Open the repository and use **Add file → Upload files**.
6. Upload the contents of this project folder.
7. Commit with:
   `Initial commit - 16-bit 3-stage pipelined ALU`

For a large project, Git/GitHub Desktop is preferable to repeated browser uploads.

## Option B — Git Bash / terminal

Open Git Bash inside this project folder.

```bash
git init -b main
git add .
git commit -m "Initial commit - 16-bit 3-stage pipelined ALU"
git remote add origin https://github.com/YOUR_USERNAME/16-bit-3stage-pipelined-ALU.git
git remote -v
git push -u origin main
```

Replace `YOUR_USERNAME` with your GitHub username.

## If Git asks for authentication

Use GitHub's normal browser/credential authentication or GitHub CLI. Do not put a password or personal access token directly into source files.

## Later updates

After changing the RTL or testbench:

```bash
git status
git add .
git commit -m "Improve pipeline forwarding"
git push
```

## Recommended commits for an academic project

If you are building it step by step, use meaningful commits:

```text
1. Add Stage 1 decode
2. Add Stage 2 ALU
3. Add Stage 3 writeback
4. Add pipeline registers
5. Add RAW forwarding
6. Add self-checking testbench
7. Add waveform verification
8. Add IEEE report and presentation
```

This makes the project history easy for a professor/interviewer to understand.
