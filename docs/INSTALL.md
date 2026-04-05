# Installation Guide — LazarusSpecKit

## Prerequisites

1. **Lazarus 4.4+** — Download from [lazarus-ide.org](https://www.lazarus-ide.org)
2. **FPC 3.2.2+** — Bundled with Lazarus installer
3. **OpenSSL** — Required for HTTPS calls to Groq API

### Checking OpenSSL on Windows

Open a terminal and run:
```cmd
where libssl-3-x64.dll
```
If not found, download from [slproweb.com/products/Win32OpenSSL.html](https://slproweb.com/products/Win32OpenSSL.html) and install.

4. **Groq API Key** — Free at [console.groq.com](https://console.groq.com)

---

## Step 1: Get the Repository

```bash
git clone https://github.com/your-user/LazarusSpecKit.git
cd LazarusSpecKit
```

The `lazarus-spec-kit` skills repo is already cloned inside the project directory.

---

## Step 2: Install the Package in Lazarus

1. Open **Lazarus 4.4**
2. Go to **Package → Open Package File (.lpk)...**
3. Navigate to `LazarusSpecKit\LazSpecWizard.lpk` and open it
4. In the Package Editor, click **Compile** — verify 0 errors
5. Click **Use → Install** (or **Package → Install Package**)
6. Lazarus will ask to rebuild — click **Yes**
7. Lazarus restarts with the plugin installed

---

## Step 3: Configure the Plugin

After Lazarus restarts:

1. Go to **Tools → Spec Wizard** (or press `Ctrl+Shift+K`)
2. The Spec Wizard panel appears (dockable, right side by default)
3. Click the ⚙️ button in the toolbar
4. Fill in your **Groq API Key**
5. Verify **Spec-Kit Path** points to `LazarusSpecKit\lazarus-spec-kit\`
   - If blank, the plugin tries to auto-detect it
6. Click **Test Connection** to verify
7. Click **OK**

---

## Step 4: Using the Wizard

Open any Lazarus project, then:

- Press `Ctrl+Shift+K` or go to **Tools → Spec Wizard**
- Select one or more **Skills** from the left panel
- Choose a **Mode**: Ask / Plan / Agent
- Type your request in the bottom text area
- Press `Enter` or click **Send**

### Quick Examples

**Ask mode:**
> How do I use TThread safely in Free Pascal?

**Plan mode:**
> Create a REST API client for the ViaCEP service with Repository pattern and FPCUnit tests

**Agent mode:**
> Create a TCustomerRepository class implementing ICustomerRepository using SQLdb and Firebird

---

## Updating Skills

Skills are loaded from the `lazarus-spec-kit` folder. To update:

1. Open Settings (⚙️)
2. Click **Update Skills** (runs `git pull` on the spec-kit folder)
3. Skills list refreshes automatically

Or manually:
```bash
cd LazarusSpecKit\lazarus-spec-kit
git pull
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "Connection failed" | Check API key in Settings; verify OpenSSL DLLs are in PATH |
| Skills panel empty | Set correct Spec-Kit Path in Settings |
| Window doesn't appear | Try **Tools → Spec Wizard** or reset window layout via **View → Reset IDE Window Layout** |
| Compilation error on install | Ensure `IDEIntf`, `LCL`, and `SynEdit` packages are installed in your Lazarus |

---

## Uninstalling

1. **Package → Installed Packages...**
2. Select `LazSpecWizard`
3. Click **Uninstall Package**
4. Confirm IDE rebuild
