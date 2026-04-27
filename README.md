# Windrose Dedicated Server (Docker + Wine)

This repository contains a fully automated Docker setup for running a **Windrose Dedicated Server** on Linux. Since the server currently only provides Windows binaries, this setup uses **Wine** and **Xvfb** (Virtual Framebuffer) to run the server in a headless, containerized environment.

## 🚀 Features

* **Automated Installation:** SteamCMD automatically downloads and updates the server on every boot.
* **Wine Optimization:** Pre-configured with necessary Windows DLL overrides (`msvcp140`, `vcruntime140`) and Visual C++ 2022 runtimes to prevent Unreal Engine crashes.
* **Auto-Healing:** Automatically cleans up "Ghost" RocksDB lock files and virtual display locks (`.X99-lock`) before startup.
* **Persistence:** All game data, logs, and configurations are stored on the host for easy management.
* **Smart Symlinking:** Automatically creates a shortcut in the root directory for easy access to the deep RocksDB Worlds folder.

---

## 🛠️ Prerequisites

* Docker and Docker Compose installed.
* **User ID Mapping:** This container runs as user `steam` (UID 1000). Ensure your host directories have the correct permissions.

---

## 📂 Project Structure

```text
.
├── Dockerfile              # Builds the Wine + SteamCMD environment
├── entrypoint.sh           # Main logic (Updates, Fixes, Auto-Config, Launch)
├── docker-compose.yml      # Container and Volume configuration
└── windrose-data/          # (Auto-created) Persistent server files
```

---

## ⏱️ Quick Start

### 1. Prepare Host Permissions

Docker creates volumes as root by default. Before launching, create the data folder and give ownership to the container user (UID 1000):

```bash
mkdir windrose-data
sudo chown -R 1000:1000 windrose-data
```

### 2. First Launch (Generate Default Files)

Start the server once so SteamCMD downloads the binaries and Windrose generates the default folder structure and `ServerDescription.json`:

```bash
docker-compose up -d --build
```

Wait until the server is fully running, then shut it down before editing config files (the server can overwrite your changes if it's still running):

```bash
docker-compose down
```

### 3. Migrate Your World, Then Configure

See the next section for the full migration + config flow. The short version: copy your world folder into the server's `Worlds` directory, then edit `ServerDescription.json` to point at it.

### 4. Re-launch

```bash
docker-compose up -d
```

---

## 🌍 How to Migrate a Local World and Configure the Server

Windrose uses a split-save system. Your character travels with you, but the world (buildings, ships, chests) must be moved to the server volume. The server then needs to be told which world to load via `ServerDescription.json`.

> ⚠️ **Always shut the server down completely before editing JSON or moving world files.** Crashes or background saves can overwrite your changes.

### 1. Locate your local save

On your Windows PC, go to:

```text
%LocalAppData%\R5\Saved\SaveProfiles\Default\RocksDB\<version>\Worlds\
```

Find the folder named with your World's UUID (a GUID-style directory name).

### 2. Copy the world into the server

* Ensure the server has been started **at least once** so the matching folder structure exists.
* Copy your entire local UUID folder into the server's worlds directory:

```text
windrose-data/R5/Saved/SaveProfiles/Default/RocksDB/<same version>/Worlds/
```

* **Shortcut:** Use the `CLICK_FOR_WORLDS` symlink inside `windrose-data` to jump straight to the correct destination.

### 3. Edit `ServerDescription.json`

Open `windrose-data/R5/ServerDescription.json` in a text editor and update the relevant fields. The most important one is `WorldIslandId` — it **must exactly match** the folder name (UUID) you just copied in.

Common fields:

* `WorldIslandId` — must match your world folder's UUID. **This is what tells the server which world to load.**
* `ServerName` — human-readable label players see.
* `InviteCode` — public handle friends type into the client; treat it like a password-lite secret. Case-sensitive, six or more characters.
* `IsPasswordProtected` / `Password` — optional extra gate on top of the invite code.
* `MaxPlayerCount` — hard cap for simultaneous clients (4 or fewer is the smoothest experience per official guidance).
* `PersistentServerId` — generated for you; **do not hand-edit**.

### 4. (Optional) Direct Connection on a Fixed Port

By default, Windrose uses NAT punch-through with dynamic ports. If you'd rather expose a fixed port (the usual default is **7777**), set these inside the existing `ServerDescription_Persistent` object in `ServerDescription.json`:

```json
"ServerDescription_Persistent": {
  "UseDirectConnection": true,
  "DirectConnectionServerAddress": "windrose.example.com:7777",
  "DirectConnectionServerPort": 7777,
  "DirectConnectionProxyAddress": "0.0.0.0"
}
```

Make sure the same port is open in your firewall and forwarded on your router for **both TCP and UDP**, and that it matches the port mapped in `docker-compose.yml`. Keep `UseDirectConnection` set to `false` if you're not using this path.

### 5. Permissions Check

Every time you manually move files into `windrose-data` from your host, re-apply permissions so the container can read them:

```bash
sudo chown -R 1000:1000 ./windrose-data
```

### 6. Start the Server and Verify

```bash
docker-compose up -d
docker-compose logs -f
```

Watch the logs to confirm the world loads and note the invite code printed to the console. The same code is also stored in `ServerDescription.json` if it scrolls past.

---

## 💡 Good to Know Tips


### 1. Switching Between Existing Worlds

If you already have multiple world folders in the server's `Worlds` directory and want to switch which one is live, **only edit `WorldIslandId` in `ServerDescription.json`** — never rename the world folders on disk. The RocksDB database ties to those IDs.

### 2. Ports

The server uses **7777 UDP** by default for direct connection. Ensure this port is open in your firewall and correctly mapped in `docker-compose.yml` if you've enabled `UseDirectConnection`.

### 3. Viewing Logs

Since the server runs in the background via Wine, use the following command to view the live Unreal Engine output:

```bash
docker-compose logs -f
```
