# Initial Setup — WSL + Docker

**Purpose:** Prepare Windows to run the YOLO object-recognition lab, which serves inference through FastAPI. These are prerequisites; the lab's own dependencies and launch steps are separate.

## 1. Install WSL and Ubuntu

1. Ensure drive **H:** is available and has enough free space.
2. Double-click `Install-WSL-H.bat` and approve the administrator prompt.
3. Restart Windows if requested, then run the BAT again if installation did not finish.
4. Open **Ubuntu** from the Start menu. Complete first-run setup by creating a Linux username and password.
5. Verify in PowerShell:
   ```powershell
   wsl --list --verbose
   ```
   Ubuntu should show version `2`.

Ubuntu is intended to be stored in `H:\WSL\Ubuntu`.

## 2. Install Docker Desktop

1. Keep `Install-DockerH.bat` and `Install-DockerH.ps1` in the **same folder**.
2. Double-click `Install-DockerH.bat` and approve the administrator prompt.
3. When installation completes, launch **Docker Desktop** from the Start menu and accept its terms.
4. In Docker Desktop, open **Settings → Resources → WSL Integration** and enable integration for **Ubuntu**. Apply the change.
5. Under **Settings → Resources → Advanced**, confirm the disk image location is on `H:`.

Target locations:

- Docker Desktop: `H:\Apps\Docker`
- Docker data: `H:\DockerData`
- Ubuntu: `H:\WSL\Ubuntu`

## 3. Verify the setup

With Docker Desktop running, open Ubuntu and run:

```bash
docker version
docker run --rm hello-world
```

Both commands should succeed. Do **not** install a separate Docker Engine with `apt` inside Ubuntu; use Docker Desktop's WSL integration.

## 4. Run the YOLO + FastAPI lab

Start Docker Desktop before running the lab. Then follow the lab repository's instructions to build/start its container or launch its FastAPI service. This setup guide does not install the lab's Python packages or model weights.

## Official references

- [Microsoft: Basic WSL commands](https://learn.microsoft.com/en-us/windows/wsl/basic-commands)
- [Docker: Install Docker Desktop on Windows](https://docs.docker.com/desktop/setup/install/windows-install/)
- [Docker: WSL integration](https://docs.docker.com/desktop/features/wsl/)
